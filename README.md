# SpellCraft AWS Integration

[![NPM version](https://img.shields.io/npm/v/@c6fc/spellcraft-aws-terraform.svg?style=flat)](https://www.npmjs.com/package/@c6fc/spellcraft-aws-terraform)
[![License](https://img.shields.io/npm/l/@c6fc/spellcraft-aws-terraform.svg?style=flat)](https://opensource.org/licenses/MIT)

This module exposes common constructs for using [SpellCraft](https://github.com/@c6fc/spellcraft) SpellFrames to deploy infrastructure to AWS using Terraform.

```sh
npm install --save @c6fc/spellcraft

# Install and expose this module with name 'awsterraform'
npx spellcraft importModule spellcraft-aws-terraform
```

## Features

This module exposes the concept of a bootstrap bucket (functionally a terraform backend), and artifacts which can contain arbitrary data and are stored alongside the terraform state in the bootstrap bucket. The former allows for dynamic configuration of Terraform providers within different environments, while the latter simplifies the storage and use of dynamic configuration details that might be environment dependent.

## CLI Commands

This plugin does not extend the SpellCraft CLI.

## SpellFrame 'init()' features

This plugin does not perform any distinct 'init' operations, other than to initialize credentials within the dependant plugin `@c6fc/terraform-aws-auth`.

## JavaScript context features

Extends the JavaScript function context with an `awsterraform` object containing the following keys:

```JSON
{ 
	"projectName": "<contains the name of the project specified by bootstrapTerraformInAWS()>",
	"bootstrapBucket": "<contains the ARN for the bootstrap bucket>",
	"bootstrapLocation": "<contains the region where the bootstrap bucket is located>"
}
```

## Exposed module functions

Exposes the following functions to JSonnet through the import module:

*	`bootstrapTerraformInAWS(project)`
*	`getTerraformInAWSArtifact(name)`
*	`getTerraformInAWSBootstrapBucket()`
*	`getTerraformInAWSRemoteState(project)`
*	`putTerraformInAWSArtifact(name, content)`

As well as the following helper functions that other AWS-based modules expect

*	`providerAliases(default)`


Generate documentation with `npm run doc` to see more detailed information about how to use these features.


## Installation

Install the plugin as a dependency in your SpellCraft project:

```bash
# Create a SpellCraft project if you haven't already
npm install --save @c6fc/spellcraft

# Install and expose this module with default name 'awsterraform'
npx spellcraft importModule spellcraft-aws-terraform
```

Once installed, you can load the module into your JSonnet files by the name you specified with `importModule`, in this case 'awsterraform':

```jsonnet
local modules = import "modules";

{
	'backend.tf.json': modules.awsterraform.bootstrapTerraformInAWS("myProjectName")
	'provider.tf.json': {
		provider: modules.awsterraform.providerAliases("us-west-2")
	}
}
```

## Documentation

You can generate JSDoc documentation for this plugin using `npm run doc`. Documentation will be generated in the `doc` folder.