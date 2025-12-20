/*
	This file should manifest all the exposed features of your module
	so users can see examples of how they are used, and the output they
	generate.
*/

local aws = import "module.libsonnet";

{
	"bootstrap.tf.json": aws.bootstrap("spellcraft-aws-terraform-module-test"),
	"test.tf.json": {
		output: {
			putArtifact: {
				value: aws.putArtifact("putArtifactTest", "mytest2")
			},
			getBootstrapBucket: {
				value: aws.getBootstrapBucket()
			},

			/* These can only be used after the project is created and the contents populated.
			getArtifact: {
				value: aws.getArtifact("putArtifactTest")
			},
			getRemoteState: {
				value: aws.getRemoteState("spellcraft-aws-terraform-module-test")
			}
			*/
		}
	},
	'providers.tf.json': {
		provider: aws.providerAliases("us-west-2")
	}
}