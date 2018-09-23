import React, { Component } from 'react';
import TokenWithdrawal from '../presentationalComponents/Withdraw/TokenWithdrawal';
import EtherWithdrawal from '../presentationalComponents/Withdraw/EtherWithdrawal';

class Withdrawal extends Component {
  state = {};
  render() {
    return (
      <div className="container">
        <div className="row">
          <div className="h1-responsive m-auto"> Withdrawal </div>
        </div>
        <div className="row">
          <div className="col-md-5 col-sm-12 offset-md-1 mt-5">
            <TokenWithdrawal />
          </div>
          <div className="col-md-5 col-sm-12 mt-5">
            <EtherWithdrawal />
          </div>
        </div>
      </div>
    );
  }
}

export default Component;
