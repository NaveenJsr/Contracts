// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery{
    address payable[] public players;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    receive() external  payable{
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == owner);
        return address(this).balance;
    }

    function random() public  view returns(uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == owner);
        require(players.length >= 3);

        uint r = random();

        address payable winner;

        uint index = r % players.length;
        winner = players[index];

        winner.transfer(getBalance());
        players = new address payable [](0);

    }
}