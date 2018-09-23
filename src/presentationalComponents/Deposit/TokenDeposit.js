import React from 'react';
import { Input, Fa, Button } from 'mdbreact';

const TokenDeposit = props => {
  return (
    <form>
      <p className="h3-responsive text-center mb-4">Deposit Token</p>
      <div className="grey-text">
        <Input label="Token Symbol Name" icon="user" />
        <Input label="Number of Tokens" icon="user" group type="text" />
      </div>
      <div className="text-center">
        <Button outline color="info">
          Deposit <Fa icon="paper-plane-o" className="ml-1" />
        </Button>
      </div>
    </form>
  );
};

export default TokenDeposit;
