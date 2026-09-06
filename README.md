# @c6fc/spellcraft-aws-terraform

S3 state backend, remote state, artifacts and provider aliases for
[SpellCraft](https://github.com/c6fc/spellcraft).

[![NPM version](https://img.shields.io/npm/v/@c6fc/spellcraft-aws-terraform.svg?style=flat)](https://www.npmjs.com/package/@c6fc/spellcraft-aws-terraform)
[![License](https://img.shields.io/npm/l/@c6fc/spellcraft-aws-terraform.svg?style=flat)](https://opensource.org/licenses/MIT)

This is the AWS half of the Terraform story: it decides where state lives, hands
one spell the values another produced, and declares the providers that
region-aware plugins bind to. `@c6fc/spellcraft-terraform` runs the apply;
this tells it what to apply against.

```bash
npm install --save @c6fc/spellcraft-aws-terraform @c6fc/spellcraft-terraform
```

## A complete spell

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";
local s3 = import "@c6fc/spellcraft-aws-s3/module.libsonnet";

{
	// State backend, and the bucket to hold it. Created on first use.
	"backend.tf.json": aws.bootstrap("my-project"),

	// One aliased provider per region, plus an unaliased default.
	"providers.tf.json": { provider: aws.providerAliases("us-east-1") },

	"buckets.tf.json": s3.bucket("artifacts", "us-west-2"),
}
```

```bash
npx spellcraft terraform-apply manifest.jsonnet
```

Three things happen before Terraform sees anything: credentials resolve, the
backend bucket is created if it is missing, and the region list is fetched to
build the providers. The rendered `.tf.json` already contains the answers.

## The bootstrap bucket

`bootstrap(project)` returns the Terraform `backend` block and makes sure the
bucket behind it exists. There is **one bucket per account**, discovered by
naming convention — `spellcraft-<random>-<digits>` — and shared by every spell,
which is why `project` is a required argument: it becomes the key prefix that
separates one spell's state from another's.

Finding more than one candidate bucket is an error rather than a guess.

## Sharing values between spells

Two ways, both resolved while the manifest evaluates rather than at apply time.

**Remote state** reads another spell's outputs:

```jsonnet
local network = aws.getRemoteState("network");

{
	"app.tf.json": {
		resource: {
			aws_instance: {
				app: { subnet_id: network.outputs.subnet_id.value },
			},
		},
	},
}
```

**Artifacts** are arbitrary JSON values written under a project's prefix,
for things that aren't Terraform outputs at all:

```jsonnet
{ "meta.json": { ok: aws.putArtifact("build", { image: "app:1.4.2" }) } }
```

```jsonnet
local build = aws.getArtifact("build");
```

Because both land during evaluation, the value can *shape* the configuration —
choosing how many resources to emit, or which branch to take — not merely appear
inside it. A Terraform data source can only do the latter.

## Provider aliases

`providerAliases(default)` emits an aliased `aws` provider for every region the
account has enabled, with the alias set to the region name, plus an unaliased
default for the region you name. Plugins then take a region as an argument and
bind to `aws.<region>` without any per-spell wiring.

It is also the reason a spell only declares providers once, no matter how many
region-aware plugins it uses.

## The auth passthrough

`aws.auth` re-exports [`@c6fc/spellcraft-aws-auth`](https://www.npmjs.com/package/@c6fc/spellcraft-aws-auth),
so a spell that already imports this module can reach the credential helpers
without a second import:

```jsonnet
{ "identity.json": aws.auth.getCallerIdentity() }
```

<!-- SPELLCRAFT_DOCS_API_START -->
## API Reference

### `bootstrap(project)`

Prepares the S3 backend for a project, creating the bootstrap bucket if it
does not exist yet, and returns the Terraform `backend` block for it.

This is the one function here that writes: it creates the bucket on first
use. State and artifacts for every project live in that one bucket, keyed
by project name.

- param {string} project - names the state prefix; use one per spell
- returns {object} a Terraform block ready to merge into a `.tf.json` file

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

{ "backend.tf.json": aws.bootstrap("my-project") }

// Returns:
// {
//   "terraform": {
//     "backend": {
//       "s3": {
//         "bucket": "spellcraft-random-0123456789",
//         "key": "spellcraft/my-project/terraform.tfstate",
//         "region": "us-east-1"
//       }
//     }
//   }
// }
```

---
### `getArtifact(name)`

Reads an artifact previously stored by `putArtifact()`.

Artifacts are how one spell hands a value to another without a Terraform
data source — the value is fetched while the manifest evaluates, so it can
shape the configuration rather than only appear in it.

- param {string} name - the artifact name given to `putArtifact()`
- returns {*} the stored value, parsed back from JSON

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

local shared = aws.getArtifact("network");

{ "app.tf.json": { resource: { aws_instance: { app: { subnet_id: shared.subnetId } } } } }
```

---
### `getBootstrapBucket()`

The name of the bootstrap bucket, or `false` when none exists yet.

Discovery is by naming convention rather than by tag, and more than one
match in the account is an error — there is meant to be exactly one.

- returns {string|boolean} the bucket name, or false

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

{ "state.json": { bucket: aws.getBootstrapBucket() } }
```

---
### `getRemoteState(project)`

Reads the Terraform state of another SpellCraft project in the same account.

Use it to consume another spell's outputs at evaluation time. The project
name is the one passed to that spell's `bootstrap()`.

- param {string} project - the other spell's project name
- returns {object} that project's Terraform state

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

local network = aws.getRemoteState("network");

{ "app.tf.json": { output: { vpc: { value: network.outputs.vpc_id.value } } } }
```

---
### `putArtifact(name, content)`

Stores a value as a JSON artifact in the bootstrap bucket, under this
project's prefix. Read it back with `getArtifact()`.

- param {string} name - the artifact name
- param {*} content - any JSON-serialisable value
- returns {boolean} true

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

{ "meta.json": { stored: aws.putArtifact("network", { subnetId: "subnet-abc123" }) } }
```

---
### `providerAliases(default)`

Builds the full set of AWS provider declarations for a spell.

Returns one aliased provider per region your credentials can see — the
alias is the region name, so resources bind to it as `aws.us-west-2` — plus
an unaliased default provider for the region you name. This is what lets
plugins like `@c6fc/spellcraft-aws-s3` take a region as an argument and
place resources in it without every spell wiring providers by hand.

The region list comes from a live `describeRegions` call, so the set
reflects what the account actually has enabled.

- param {string} default - region for the unaliased default provider
- returns {object[]} provider declarations, for the `provider` key of a `.tf.json`

**Examples:**

```jsonnet
local aws = import "@c6fc/spellcraft-aws-terraform/module.libsonnet";

{ "providers.tf.json": { provider: aws.providerAliases("us-east-2") } }

// Returns:
// [
//   { "aws": { "alias": "us-east-1", "region": "us-east-1" } },
//   { "aws": { "alias": "us-west-2", "region": "us-west-2" } },
//   ...
//   { "aws": { "region": "us-east-2" } }
// ]
```

---

<!-- SPELLCRAFT_DOCS_API_END -->

## Development

```bash
npm test        # renders test.jsonnet through a real SpellFrame
npm run doc     # regenerates the API section above from module.libsonnet
```

`npm test` **writes**: it creates the bootstrap bucket if your account has none,
and stores an artifact in it.

## License

MIT © [Brad Woodward](https://github.com/c6fc)
