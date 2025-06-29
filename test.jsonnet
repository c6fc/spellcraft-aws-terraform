/*
	`npm run test` and `npm run cli` always links the current module as 'foo'.
	
	This file should manifest all the exposed features of your module
	so users can see examples of how they are used, and the output they
	generate.
*/

local foo = import "foo.libsonnet";

{
	"bootstrap.tf.json": foo.bootstrapTerraformInAWS("spellcraft-aws-terraform-module-test"),
	"test.tf.json": {
		output: {
			putTerraformInAWSArtifact: {
				value: foo.putTerraformInAWSArtifact("putArtifactTest", "mytest2")
			},
			getTerraformInAWSBootstrapBucket: {
				value: foo.getTerraformInAWSBootstrapBucket()
			},

			/* These can only be used after the project is created and the contents populated.
			getTerraformInAWSArtifact: {
				value: foo.getTerraformInAWSArtifact("putArtifactTest")
			},
			getTerraformInAWSRemoteState: {
				value: foo.getTerraformInAWSRemoteState("spellcraft-aws-terraform-module-test")
			}
			*/
		}
	},
	'providers.tf.json': {
		provider: foo.providerAliases("us-west-2")
	}
}