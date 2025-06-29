'use strict';

/*
	This is a pre-written test-case wrapper
	for local module development. Populate
	../test.jsonnet with tests of your
	module capabilities, using 'import "foo.libsonnet"'

	Run with `npm run test`
*/

const info = require("../package.json");
const { SpellFrame } = require('@c6fc/spellcraft');
const { _spellcraft_metadata } = require('../module.js');

const spellframe = new SpellFrame();

(async () => {
	spellframe.loadModuleByName("foo", "..");
	spellframe.loadModuleByName("awsauth", "@c6fc/spellcraft-aws-auth");
	spellframe.init();
	await spellframe.render("./test.jsonnet");

	console.log(JSON.stringify(spellframe.lastRender, null, 4));
})();