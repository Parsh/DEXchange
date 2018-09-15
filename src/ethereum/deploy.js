const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledERC20Interface = require('./build/ERC20Interface.json');
const compiledDEXtoken = require('./build/DEXtoken.json');
const compiledExchange = require('./build/Exchange.json');
const config = require('./production/config');

const provider = new HDWalletProvider(config.MNEMONIC, config.NETWORKURL);
const web3 = new Web3(provider);

let accounts;

// const deployERC20Interface = async () => {
//   accounts = await web3.eth.getAccounts();
//   console.log('deploying...');
//   ERC20Interface = await new web3.eth.Contract(
//     JSON.parse(compiledERC20Interface.interface)
//   )
//     .deploy({
//       data: '0x' + compiledERC20Interface.bytecode
//     })
//     .send({
//       from: accounts[0],
//       gas: '5000000'
//     });

//   console.log(
//     'ERC20Interface is deployed! Contract Address: ',
//     ERC20Interface.options.address
//   );
// };

const deployDEXtoken = async () => {
  accounts = await web3.eth.getAccounts();
  DEXtoken = await new web3.eth.Contract(JSON.parse(compiledDEXtoken.interface))
    .deploy({
      data: '0x' + compiledDEXtoken.bytecode
    })
    .send({
      from: accounts[0],
      gas: '6000000'
    });

  console.log(
    'DEXtoken is deployed! Contract Address: ',
    DEXtoken.options.address
  );
};

const deployExchange = async () => {
  Exchange = await new web3.eth.Contract(JSON.parse(compiledExchange.interface))
    .deploy({
      data: '0x' + compiledExchange.bytecode
    })
    .send({
      from: accounts[0],
      gas: '6500000'
    });

  console.log(
    'Exchange is deployed! Contract Address: ',
    Exchange.options.address
  );
};

deployDEXtoken().then(deployExchange);
