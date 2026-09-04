// Don't try to 'import' your spellcraft native functions here.
// Use std.native(function)(..args) instead

local auth = import "@c6fc/spellcraft-aws-auth/module.libsonnet";

{
	// JS Native functions are already documented in spellcraft_modules/foo.js
	// but need to be specified here to expose them through the import

	/**
	 * Direct passthrough of the @c6fc/spellcraft-aws-auth
	 */
	auth: auth,

	/**
	 * Creates a Terraform backend bucket if one doesn't already exist, then
	 * returns a 'backend' object referencing this bucket and a unique path
	 * for this project's state and artifacts.
	 *
	 * @param {string} project
	 * @returns {object} backend
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.bootstrap("myBootstrapTest");
	 *
	 * // Returns:
	 * {
	 *    "terraform": {
	 *        "backend": {
	 *            "s3": {
	 *                "bucket": "spellcraft-random-0123456789",
	 *                "key": "spellcraft/myBootstrapTest/terraform.tfstate",
	 *                "region": "us-east-1"
	 *            }
	 *        }
	 *    }
	 * }
	 */
	bootstrap(project):: std.native("@c6fc/spellcraft-aws-terraform:bootstrap")(project),

	/**
	 * Obtains the contents of a named artifact stored alongside this project in the bootstrap
	 * bucket. This artifact is created with 'putArtifact';
	 *
	 * @param {string} name
	 * @returns {object} backend
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.getArtifact("myArtifact");
	 *
	 * // Returns:
	 * <contents of your artifact>
	 */
	getArtifact(name):: std.native("@c6fc/spellcraft-aws-terraform:getArtifact")(name),

	/**
	 * Attempts to discover the bucket created through bootstrap(), returning the
	 * bucket name if present, or false if no bootstrap bucket exists yet.
	 *
	 * @returns {string} bucketName
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.getBootstrapBucket();
	 *
	 * // Returns:
	 * spellcraft-random-0123456789
	 */
	getBootstrapBucket():: std.native("@c6fc/spellcraft-aws-terraform:getBootstrapBucket")(),

	/**
	 * Read the Terraform state for an adjacent SpellCraft project in the same AWS account
	 *
	 * @param {string} project
	 * @returns {object} state
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.getRemoteState("mySecondProject");
	 *
	 * // Returns:
	 * { full remote state object }
	 */
	getRemoteState(project):: std.native("@c6fc/spellcraft-aws-terraform:getRemoteState")(project),

	/**
	 * Stores the JSON-encoded balue of 'contents' as a file in the S3 backend bucket using
	 * the project prefix.
	 *
	 * @param {string} name
	 * @param {*} contents
	 * @returns {boolean} true
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.putArtifact("myArtifact", { someData: someValue });
	 *
	 * // Returns:
	 * true
	 */
	putArtifact(name, content):: std.native("@c6fc/spellcraft-aws-terraform:putArtifact")(name, content),

	/**
	 * Stores the JSON-encoded balue of 'contents' as a file in the S3 backend bucket using
	 * the project prefix.
	 *
	 * @param {string} default
	 * @returns {object} terraformProviderConfig
	 * @example
	 * local aws = import "@c6fc/spellcraft-aws-terraform";
	 *
	 * aws.providerAliases("us-east-2");
	 *
	 * // Returns:
	 * [{ aws: {
	 *		region: "us-east-2"
	 * }}, { aws: {
	 *		region: "us-east-1",
			alias: "aws.us-east-1"
	 * }}, ...]
	 */
	providerAliases(default):: [{
		aws: {
			alias: region,
			region: region
		}
	} for region in std.map(
		function(x) x.RegionName,
		std.native("@c6fc/spellcraft-aws-auth:aws")('{ "service": "EC2", "params": { "region": "us-east-1" } }', "describeRegions", "{}").Regions
	)] + [{
		aws: {
			region: default
		}
	}]

}