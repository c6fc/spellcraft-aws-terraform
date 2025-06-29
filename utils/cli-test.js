#! /usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');
const yargs = require('yargs');
const { hideBin } = require('yargs/helpers');
const { SpellFrame } = require('@c6fc/spellcraft');
const { _spellcraft_metadata } = require('../module.js');

const spellframe = new SpellFrame();

spellframe.loadModuleByName("foo", ".."); // a name of '..' loads the current module.
spellframe.loadModuleByName("terraform", "@c6fc/spellcraft-terraform");

// Raise an alert if there's a spellcraft_modules directory, since this isn't allowed for modules.
if (fs.existsSync(path.resolve('..', 'spellcraft_modules'))) {
	throw new Error(`[!] This module has a spellcraft_modules directory. This isn't permitted. Instead, native `
		+ `functions should be exposed through your modules.js file. Migrate your functions and remove the `
		+ `spellcraft_modules directory before continuing`);
}


(async () => {
	
	let cli = yargs(hideBin(process.argv))
		.usage("Syntax: $0 <command> [options]")
		.scriptName("spellcraft")

		.command("generate <filename>", "Generates files from a configuration", (yargsInstance) => {
			return yargsInstance.positional('filename', {
				describe: 'Jsonnet configuration file to consume',
				type: 'string',
				demandOption: true,
			});
		},
		async (argv) => { // No JSDoc for internal handler
			try {
				await spellframe.init();
				console.log(`[+] Rendering configuration from: ${argv.filename}`);
				await spellframe.render(argv.filename);
				await spellframe.write();
				console.log("[+] Generation complete.");
			} catch (error) {
				console.error(`[!] Error during generation: ${error.message}`);
				process.exit(1);
			}
		})

	// No JSDoc for CLI extensions loop if considered internal detail
	if (spellframe.cliExtensions && spellframe.cliExtensions.length > 0) {
		spellframe.cliExtensions.forEach((extensionFn) => {
			if (typeof extensionFn === 'function') {
				extensionFn(cli, spellframe);
			}
		});
	}

	cli
		.demandCommand(1, 'You need to specify a command.')
		.recommendCommands()
		.strict()
		.showHelpOnFail(true)
		.help("help")
		.alias('h', 'help')
		.version()
		.alias('v', 'version')
		.epilogue('For more information, consult the SpellCraft documentation.')
		.argv;
})();