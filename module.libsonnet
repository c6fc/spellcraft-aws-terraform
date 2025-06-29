/**
 * @module spellcraft-aws-terraform
 * @description This module represents the JSonnet and JavaScript native
 * functions exposed by this plugin.
 */

// Don't try to 'import' your spellcraft native functions here.
// Use std.native(function)(..args) instead

{
	// JS Native functions are already documented in spellcraft_modules/foo.js
	// but need to be specified here to expose them through the import

	/**
	 * Creates a Terraform backend bucket if one doesn't already exist, then
	 * returns a 'backend' object referencing this bucket and a unique path
	 * for this project's state and artifacts.
	 *
	 * @function bootstrapTerraformInAWS
	 * @param {string} project
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {object} backend
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.bootstrapTerraformInAWS("myBootstrapTest");
	 *
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
	bootstrapTerraformInAWS(project):: std.native("bootstrapTerraformInAWS")(project),

	/**
	 * Obtains the contents of a named artifact stored alongside this project in the bootstrap
	 * bucket. This artifact is created with 'putTerraformInAWSArtifact';
	 *
	 * @function getTerraformInAWSArtifact
	 * @param {string} name
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {object} backend
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.getTerraformInAWSArtifact("myArtifact");
	 *
	 * <contents of your artifact>
	 */
	getTerraformInAWSArtifact(name):: std.native("getTerraformInAWSArtifact")(name),

	/**
	 * Attempts to discover the bucket created through bootstrapTerraformInAWS(), returning the
	 * bucket ARN if present.
	 *
	 * @function getTerraformInAWSBootstrapBucket
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {string} bucketArn
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.bootstrapTerraformInAWS("myProject");
	 * awsterraform.getTerraformInAWSBootstrapBucket();
	 *
	 * arn:aws:s3:::spellcraft-random-0123456789
	 */
	getTerraformInAWSBootstrapBucket():: std.native("getTerraformInAWSBootstrapBucket")(),

	/**
	 * Read the Terraform state for an adjacent SpellCraft project in the same AWS account
	 *
	 * @function getTerraformInAWSRemoteState
	 * @param {string} project
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {object} state
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.getTerraformInAWSRemoteState("mySecondProject");
	 *
	 * { full remote state object }
	 */
	getTerraformInAWSRemoteState(project):: std.native("getTerraformInAWSRemoteState")(project),

	/**
	 * Stores the JSON-encoded balue of 'contents' as a file in the S3 backend bucket using
	 * the project prefix.
	 *
	 * @function putTerraformInAWSArtifact
	 * @param {string} name
	 * @param {*} contents
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {boolean} true
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.putTerraformInAWSArtifact("myArtifact", { someData: someValue });
	 *
	 * true
	 */
	putTerraformInAWSArtifact(name, content):: std.native("putTerraformInAWSArtifact")(name, content),

	/**
	 * Stores the JSON-encoded balue of 'contents' as a file in the S3 backend bucket using
	 * the project prefix.
	 *
	 * @function providerAliases
	 * @param {string} default
	 * @memberof module:spellcraft-aws-terraform
	 * @returns {object} terraformProviderConfig
	 * @example
	 * local awsterraform = import "awsterraform.libsonnet";
	 * awsterraform.providerAliases("us-east-2");
	 *
	 * true
	 */
	providerAliases(default):: [{
		aws: {
			alias: region,
			region: region
		}
	} for region in std.map(
		function(x) x.RegionName,
		std.native("aws")('{ "service": "EC2", "params": { "region": "us-east-1" } }', "describeRegions", "{}").Regions
	)] + [{
		aws: {
			region: default
		}
	}]

}