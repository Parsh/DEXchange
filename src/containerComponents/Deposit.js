import React, { Component } from 'react';
import TokenDeposit from '../presentationalComponents/Deposit/TokenDeposit';
import EtherDeposit from '../presentationalComponents/Deposit/EtherDeposit';

class Deposit extends Component {
  state = {};
  render() {
    return (
      <div className="row">
        <div className="col-md-6">
          <TokenDeposit />
        </div>
        <div className="col-md-6">
          <EtherDeposit />
        </div>
      </div>
    );
  }
}

export default Deposit;
