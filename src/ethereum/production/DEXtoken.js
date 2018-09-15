import web3 from './web3';
import compiledDEXtoken from '../build/DEXtoken.json';

const DEXtoken = new web3.eth.Contract(
  JSON.parse(compiledDEXtoken.interface),
  '0xfB22E685Dc7158E5011Fb8185f78384561599071'
);

export default DEXtoken;
