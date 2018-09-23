import React, { Component } from 'react';
import TokenDeposit from '../presentationalComponents/Deposit/TokenDeposit';
import EtherDeposit from '../presentationalComponents/Deposit/EtherDeposit';

class Deposit extends Component {
  state = {};
  render() {
    return (
      <div className="container mb-4">
        <div className="row">
          <div className="h1-responsive m-auto"> Deposit </div>
        </div>
        <div className="row">
          <div className="col-md-5 col-sm-12 offset-md-1 mt-5">
            <TokenDeposit />
          </div>
          <div className="col-md-5 col-sm-12 mt-5">
            <EtherDeposit />
          </div>
        </div>
      </div>
    );
  }
}

export default Deposit;
