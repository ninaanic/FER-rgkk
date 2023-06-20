// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint internal highestBid;
    uint internal initialPrice;
    uint internal biddingPeriod;
    uint internal lastBidTimestamp;
    uint internal minimumPriceIncrement;

    address internal highestBidder;
    bool successful_auction = false;

    constructor(
        address _sellerAddress,
        address _judgeAddress,
        Timer _timer,
        uint _initialPrice,
        uint _biddingPeriod,
        uint _minimumPriceIncrement
    ) Auction(_sellerAddress, _judgeAddress, _timer) {
        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

        // Start the auction at contract creation.
        lastBidTimestamp = time();
    }

    function bid() public payable {
        require(time() - lastBidTimestamp < biddingPeriod, "Can not bid after bidding period ended"); // aukcija jos traje 

        // nitko jos nije dao ponudu 
        if (highestBid == 0) {
            if (msg.value >= initialPrice) {
                // sold!
                highestBid = msg.value;
                highestBidderAddress = msg.sender;
                lastBidTimestamp = time();
            }
            else {
                // price offered lower than initialPrice, return money
                payable(msg.sender).transfer(msg.value); // vrati novce 
                require(msg.value >= initialPrice + minimumPriceIncrement, "Price offered must be at least initial bid + price increment");
            }
        // nije 1. ponuda ali je veca od trenutno najvece + increment --> dozvoli kupnju 
        } else if (msg.value >= highestBid + minimumPriceIncrement) {
            // vrati prethodnom potenijalnom kupcu njegove novce 
            payable(highestBidderAddress).transfer(highestBid); 

            // sold!
            highestBid = msg.value;
            highestBidderAddress = msg.sender;
            lastBidTimestamp = time();
        // nije 1. ponuda ali je manja od trenutno najvece + increment --> nemoj dozvolit kupnju 
        } else {
            // price offered lower than initialPrice, return money
            payable(msg.sender).transfer(msg.value); // vrati novce 
            require(msg.value >= highestBid + minimumPriceIncrement, "Price offered must be at least highest bid + price increment");
        }
    }

    function getHighestBidder() override public returns (address) {
        // ako je aukiaukcijacja zavrsena vrati highestBidderAddress
        if (time() - lastBidTimestamp >= biddingPeriod) {
            return highestBidderAddress;
        }
        return address(0);
    }

    // ako je aukcija neuspjesno zavrsena vrati NOT_SUCCESSFUL
    function enableRefunds() public {
        require(time() - lastBidTimestamp >= biddingPeriod, "Can not enable refund before bidding ended");
        outcome = Outcome.NOT_SUCCESSFUL;
    }

}