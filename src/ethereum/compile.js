const path = require('path');
const solc = require('solc');
const fs = require('fs-extra');

const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);

const ERC20Interface = path.resolve(
  __dirname,
  'contracts',
  'ERC20Interface.sol'
);
const DEXtoken = path.resolve(__dirname, 'contracts', 'DEXtoken.sol');
const Exchange = path.resolve(__dirname, 'contracts', 'Exchange.sol');

const input = {
  'ERC20Interface.sol': fs.readFileSync(ERC20Interface, 'utf8'),
  'DEXtoken.sol': fs.readFileSync(DEXtoken, 'utf8'),
  'Exchange.sol': fs.readFileSync(Exchange, 'utf8')
};

output = solc.compile({ sources: input }).contracts;

fs.ensureDirSync(buildPath);

for (let contract in output) {
  fs.outputJSONSync(
    path.resolve(
      buildPath,
      contract.substring(0, contract.indexOf('.')) + '.json'
    ),
    output[contract]
  );
}
