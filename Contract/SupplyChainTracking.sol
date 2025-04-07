// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SupplyChainTracking {
    enum Role { Manufacturer, Distributor, Retailer }
    enum State { Created, InTransit, Delivered }

    struct Participant {
        string name;
        Role role;
        address account;
    }

    struct Product {
        uint256 id;
        string name;
        address currentOwner;
        State state;
        address[] history;
    }

    uint256 public productCounter;
    mapping(address => Participant) public participants;
    mapping(uint256 => Product) public products;

    event ParticipantRegistered(address account, string name, Role role);
    event ProductCreated(uint256 productId, string name, address owner);
    event OwnershipTransferred(uint256 productId, address from, address to);

    modifier onlyRegistered() {
        require(bytes(participants[msg.sender].name).length != 0, "Not a registered participant");
        _;
    }

    function registerParticipant(string memory _name, Role _role) public {
        require(bytes(participants[msg.sender].name).length == 0, "Already registered");

        participants[msg.sender] = Participant({
            name: _name,
            role: _role,
            account: msg.sender
        });

        emit ParticipantRegistered(msg.sender, _name, _role);
    }

    function createProduct(string memory _name) public onlyRegistered {
        require(participants[msg.sender].role == Role.Manufacturer, "Only manufacturer can create product");

        productCounter++;
        Product storage p = products[productCounter];

        p.id = productCounter;
        p.name = _name;
        p.currentOwner = msg.sender;
        p.state = State.Created;
        p.history.push(msg.sender);

        emit ProductCreated(productCounter, _name, msg.sender);
    }

    function transferProduct(uint256 _productId, address _to) public onlyRegistered {
        Product storage p = products[_productId];
        require(p.currentOwner == msg.sender, "Only current owner can transfer");
        require(bytes(participants[_to].name).length != 0, "Receiver not registered");

        Role senderRole = participants[msg.sender].role;
        Role receiverRole = participants[_to].role;

        require(
            (senderRole == Role.Manufacturer && receiverRole == Role.Distributor) ||
            (senderRole == Role.Distributor && receiverRole == Role.Retailer),
            "Invalid role transfer"
        );

        p.currentOwner = _to;
        p.state = senderRole == Role.Manufacturer ? State.InTransit : State.Delivered;
        p.history.push(_to);

        emit OwnershipTransferred(_productId, msg.sender, _to);
    }

    function getProductDetails(uint256 _productId) public view returns (
        string memory name,
        address currentOwner,
        State state,
        address[] memory history
    ) {
        Product storage p = products[_productId];
        return (p.name, p.currentOwner, p.state, p.history);
    }
} 
