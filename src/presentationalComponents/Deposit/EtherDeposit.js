import React from 'react';

import { Input, Button, Fa } from 'mdbreact';

const EtherDeposit = props => {
  return (
    <form>
      <p className="h3-responsive text-center mb-4">Deposit Ether</p>
      <div className="grey-text">
        <Input label="Amount in Ether" icon="user" group type="text" />
      </div>
      <div className="text-center">
        <Button outline color="info">
          Deposit <Fa icon="paper-plane-o" className="ml-1" />
        </Button>
      </div>
    </form>
  );
};

export default EtherDeposit;
