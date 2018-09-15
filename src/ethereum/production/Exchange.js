import web3 from './web3';
import compiledExchange from '../build/Exchange.json';

const Exchange = new web3.eth.Contract(
  JSON.parse(compiledExchange.interface),
  '0xDF334875c6122853BD4Ac19E4bF9649EFc5Cd0bb'
);

export default Exchange;
