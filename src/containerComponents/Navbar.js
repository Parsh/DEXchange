import React, { Component } from 'react';
import {
  Navbar,
  NavbarBrand,
  NavbarNav,
  NavbarToggler,
  Collapse,
  NavItem,
  NavLink,
  Dropdown,
  DropdownToggle,
  DropdownMenu,
  DropdownItem
} from 'mdbreact';
import { BrowserRouter as Router } from 'react-router-dom';

class NavbarFeatures extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      collapse: false,
      isWideEnough: false
    };
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    this.setState({
      collapse: !this.state.collapse
    });
  }
  render() {
    return (
      <Router>
        <Navbar color="bg-primary" dark expand="md" fixed="top" scrolling>
          <NavbarBrand className="text-white">
            <strong>DEXchange</strong>
          </NavbarBrand>
          {!this.state.isWideEnough && <NavbarToggler onClick={this.onClick} />}
          <Collapse isOpen={this.state.collapse} navbar>
            <NavbarNav left>
              <NavItem active>
                <NavLink to="#">Exchange Overview</NavLink>
              </NavItem>
              <NavItem>
                <NavLink to="#">DEX Token Trading</NavLink>
              </NavItem>
              <NavItem>
                <NavLink to="#">Manage Token</NavLink>
              </NavItem>
            </NavbarNav>
          </Collapse>
        </Navbar>
      </Router>
    );
  }
}

export default NavbarFeatures;
