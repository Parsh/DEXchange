import React from 'react';
import { Input, Fa, Button } from 'mdbreact';

const TokenWithdrawal = props => {
  return (
    <form>
      <p className="h4-responsive text-center mb-4">Withdraw Token</p>
      <div className="grey-text">
        <Input label="Token Symbol Name" icon="user" />
        <Input label="Number of Tokens" icon="user" group type="text" />
      </div>
      <div className="text-center">
        <Button outline color="info">
          Withdraw <Fa icon="paper-plane-o" className="ml-1" />
        </Button>
      </div>
    </form>
  );
};

export default TokenWithdrawal;
