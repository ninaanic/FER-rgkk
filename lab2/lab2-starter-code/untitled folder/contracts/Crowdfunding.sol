// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Timer.sol";

/// This contract represents most simple crowdfunding campaign.
/// This contract does not protects investors from not receiving goods
/// they were promised from crowdfunding owner. This kind of contract
/// might be suitable for campaigns that does not promise anything to the
/// investors except that they will start working on some project.
/// (e.g. almost all blockchain spinoffs.)
contract Crowdfunding {

    address private owner;

    Timer private timer;

    uint256 public goal;

    uint256 public endTimestamp;

    uint256 private currentBalance;

    mapping (address => uint256) public investments; //  key-value struktura 

    constructor(
        address _owner,
        Timer _timer,
        uint256 _goal,
        uint256 _endTimestamp
    ) {
        owner = (_owner == address(0) ? msg.sender : _owner);
        timer = _timer; // Not checking if this is correctly injected.
        goal = _goal;
        endTimestamp = _endTimestamp;
        currentBalance = 0;
    }

    
    function invest() public payable {
        // invest ako vrijeme nije istaklo i ako goal nije dosegnut i ako investitor inveztira poz iznos
        require(timer.getTime() < endTimestamp, "Time for investing has passed.");
        require(currentBalance < goal, "The goal has been reached, no refund is possible.");
        require(msg.value >= 0, "Un-donating is not allowed!");
        
        // invest 
        currentBalance += msg.value;
        investments[msg.sender] += msg.value;
    }

    // dosegnut je goal u grupnom prikupljanju --> prikupljac kupi prikupljeni iznos 
    function claimFunds() public {
        // claim ako je zavrseno prikupljenje, pikupljeno je vise od goal i owner si
        require(timer.getTime() > endTimestamp, "Time for claiming funds has not come yet.");
        require(currentBalance >= goal, "The goal has not been reached yet.");
        require(msg.sender == owner, "Non-owners can not claim funds!");

        // claim
        payable(owner).transfer(currentBalance);
    }

    // nije doesgnut goal u grupnom prikupljanju a vrijeme je zavrsilo --> vrati novce investitorima 
    function refund() public {
        // vrati novce ako je vrijeme prikupljanja zavreno i nije dosegnut goal
        require(timer.getTime() > endTimestamp, "Time for refund funds has not come yet.");
        require(currentBalance < goal, "The goal has been reached, no refund is possible.");

        // vrati svakome kolko je dao
        payable(msg.sender).transfer(investments[msg.sender]);
        investments[msg.sender] = 0;
    }
    
}