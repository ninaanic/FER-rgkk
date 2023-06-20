// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public priceDecrement;

    uint internal auctionEnd;
    uint internal auctionStart;

    /// Creates the DutchAuction contract.
    ///
    /// @param _sellerAddress Address of the seller.
    /// @param _judgeAddress Address of the judge.
    /// @param _timer Timer reference
    /// @param _initialPrice Start price of dutch auction.
    /// @param _biddingPeriod Number of time units this auction lasts.
    /// @param _priceDecrement Rate at which price is lowered for each time unit
    ///                        following linear decay rule.
    constructor(
        address _sellerAddress,
        address _judgeAddress,
        Timer _timer,
        uint _initialPrice,
        uint _biddingPeriod,
        uint _priceDecrement
    )  Auction(_sellerAddress, _judgeAddress, _timer) {
        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        priceDecrement = _priceDecrement;
        auctionStart = time();
        // Here we take light assumption that time is monotone
        auctionEnd = auctionStart + _biddingPeriod;
    }

    /// In Dutch auction, winner is the first pearson who bids with
    /// bid that is higher than the current prices.
    /// This method should be only called while the auction is active.
    function bid() public payable {
        require(getAuctionOutcome() == Outcome.NOT_FINISHED, "No bidding is allowed after having finished");
        uint256 currTime = time();
        uint256 aucDuration = currTime - auctionStart;
        require(currTime < auctionEnd, "Can not bid after end");

        if(msg.value >= initialPrice - (priceDecrement * aucDuration)) {
            // sold!
            highestBidderAddress = msg.sender;
            payable(msg.sender).transfer(msg.value - (initialPrice - (priceDecrement * aucDuration))); // vrati ostatak 

            outcome = Outcome.SUCCESSFUL;   // kupljeno 
            auctionEnd = currTime;          // zavrena aukcija 
        }
        else {
            // no selling, no bidding is allowed under current price
            payable(msg.sender).transfer(msg.value); // vrati sve 
            require(msg.value >= initialPrice - (priceDecrement * aucDuration), "Bid is too low");

        }
    }

    // ako je aukcija neuspjesno zavrsila postavi mogucnost povrata sredstava 
    function enableRefunds() public {
        if(getAuctionOutcome() == Outcome.NOT_FINISHED) {
            outcome = Outcome.NOT_SUCCESSFUL;
        }
    }
}