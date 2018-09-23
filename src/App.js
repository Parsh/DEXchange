import React, { Component } from 'react';
import 'font-awesome/css/font-awesome.min.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'mdbreact/dist/css/mdb.css';

import Navbar from './containerComponents/Navbar';
import Deposit from './containerComponents/Deposit';

class App extends Component {
  render() {
    return (
      <div>
        <Navbar />
        <div className="container" style={{ marginTop: '100px' }}>
          <Deposit />
        </div>
      </div>
    );
  }
}

export default App;
