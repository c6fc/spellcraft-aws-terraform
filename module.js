'use strict';

process.env.AWS_SDK_JS_SUPPRESS_MAINTENANCE_MODE_MESSAGE=1

const fs = require("fs");
const os = require("os");

// Nab the authenticated AWS instantiation from aws-auth
const awsauth = require("@c6fc/spellcraft-aws-auth");
const { aws } = awsauth._spellcraft_metadata.functionContext;

// Initialize caches
const artifacts = {};
const awsterraform = { projectName: false, bootstrapBucket: false, bootstrapLocation: false };
const remoteStates = {};

exports._spellcraft_metadata = {
	functionContext: { awsterraform }
}

exports.bootstrap = [async function (project) {
	return await bootstrap(project);
}, "project"];

exports.getArtifact = [async function (name) {
	return await getArtifact(name);
}, "name"];

exports.getBootstrapBucket = [async function () {
	return await getBootstrapBucket();
}];

exports.getRemoteState = [async function (project) {
	return await getRemoteState(project);
}, "project"];

exports.putArtifact = [async function (name, content) {
	return await putArtifact(name, content);
}, "name", "content"];

async function bootstrap(project) {
	const s3 = new aws.S3();
	
	let bucketName;
	let bootstrapBucket = await getBootstrapBucket();

	if (!bootstrapBucket) {
		bucketName = `spellcraft-${Math.random().toString(36).replace(/[^a-z]+/g, '')}-${Math.round(Date.now() / 1000)}`;

		try {
			await s3.createBucket({
				Bucket: bucketName
			}).promise();

			await s3.putBucketTagging({
				Bucket: bucketName,
				Tagging: {
					TagSet: [{
						Key: "spellcraft-backend",
						Value: "true"
					}]
				}
			}).promise();

			await s3.putBucketVersioning({
				Bucket: bucketName,
				VersioningConfiguration: {
					MFADelete: "Disabled",
					Status: "Enabled"
				}
			}).promise();

			await s3.putPublicAccessBlock({
				Bucket: bucketName,
				PublicAccessBlockConfiguration: {
					BlockPublicAcls: true,
					BlockPublicPolicy: true,
					IgnorePublicAcls: true,
					RestrictPublicBuckets: true
				}
			}).promise();

			await s3.putBucketPolicy({
				Bucket: bucketName,
				Policy: JSON.stringify({
					Version: "2012-10-17",
					Statement: [{
						Sid: "AllowSSLOnly",
						Principal: "*",
						Action: "s3:*",
						Effect: "Deny",
						Resource: [
							`arn:aws:s3:::${bucketName}`,
							`arn:aws:s3:::${bucketName}/*`
						],
						Condition: {
							Bool: {
								"aws:SecureTransport": false
							}
						}
					}]
				})
			}).promise();
		} catch (e) {
			console.log(`SpellCraft error: Unable to create bucket: ${e}`);
			process.exit(1);
		}

		console.log(`[+] Created bootstrap bucket ${bucketName}`);

		bootstrapBucket = `arn:aws:s3:::${bucketName}`;
	} else {
		bucketName = bootstrapBucket;
		console.log(`[+] Using bootstrap bucket ${bucketName}`);
	}

	let bootstrapLocation = await s3.getBucketLocation({
		Bucket: bucketName
	}).promise();

	bootstrapLocation = (bootstrapLocation.LocationConstraint == '') ? "us-east-1" : bootstrapLocation.LocationConstraint;

	awsterraform.projectName = project;
	awsterraform.bootstrapBucket = bootstrapBucket;
	awsterraform.bootstrapLocation = bootstrapLocation;

	return {
		terraform: {
			backend: {
				s3: {
					bucket: bucketName,
					key: `spellcraft/${project}/terraform.tfstate`,
					region: bootstrapLocation
				}
			}
		}
	}
}

async function getBootstrapBucket() {

	if (!!awsterraform.bootstrapBucket) {
		return awsterraform.bootstrapBucket;
	}

	const s3 = new aws.S3();
	const buckets = await s3.listBuckets().promise();

	const arns = buckets.Buckets
		.map(e => e.Name)
		.filter(e => /^spellcraft-[a-z]*?-\d{10}$/.test(e));

	if (arns.length == 1) {
		return arns[0];
	}

	if (arns.length > 1) {
		throw new Error("[!] More than one bootstrap bucket exists in this account. Fix this before continuing.");
	}

	return false;
}

async function getRemoteState(project) {

	if (!!!remoteStates[project]) {
		await getBootstrapBucket();

		const s3 = new aws.S3({ region: awsterraform.bootstrapBucketLocation });

		let stateJson;

		try {
			stateJson = await s3.getObject({
				Bucket: awsterraform.bootstrapBucket,
				Key: `sonnetry/${project}/terraform.tfstate`
			}).promise();

		} catch(e) {
			throw new Error(`[!] Unable to retrieve remote state for project [ ${project} ]: ${e}`);
		}

		const state = JSON.parse(stateJson.Body);

		const resources = state.resources.reduce((a, c) => {
			let path;

			if (c.mode == "data") {
				a.data = (!a.data) ? {} : a.data;
				a.data[c.type] = (!a.data[c.type]) ? {} : a.data[c.type];

				path = a.data[c.type];
			} else {
				a[c.type] = (!a[c.type]) ? {} : a[c.type];

				path = a[c.type];
			}

			path[c.name] = (c.instances.length == 1) ? c.instances[0].attributes : c.instances.map(e => e.attributes);

			return a;
		}, {});

		resources.outputs = Object.keys(state.outputs).reduce((a, c) => {
			a[c] = state.outputs[c].value;

			return a;
		}, {});

		// console.log(resources.outputs);

		remoteStates[project] = resources;
	}

	return resources;
}

async function getArtifact(name) {

	if (!!!artifacts[name]) {
		await getBootstrapBucket();

		const s3 = new aws.S3({ region: (awsterraform.bootstrapBucketLocation || 'us-east-1') });

		const object = await s3.getObject({
			Bucket: awsterraform.bootstrapBucket,
			Key: `sonnetry/${awsterraform.projectName}/artifacts/${name}`
		}).promise();

		artifacts[name] = object?.Body;
	}

	return artifacts[name];
}

async function putArtifact(name, content) {

	if (!artifacts[name] !== content) {
		await getBootstrapBucket();

		const s3 = new aws.S3({ region: (awsterraform.bootstrapBucketLocation || 'us-east-1') });

		const object = await s3.putObject({
			Body: new Buffer.from(JSON.stringify(content)),
			Bucket: awsterraform.bootstrapBucket,
			Key: `sonnetry/${awsterraform.projectName}/artifacts/${name}`
		}).promise();

		artifacts[name] = content;
	}

	return true;
}