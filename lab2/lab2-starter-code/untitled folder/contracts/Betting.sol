// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxOracle.sol";

contract Betting {

    struct Player {
        uint8 id;
        string name;
        uint totalBetAmount;
        uint currCoef; 
    }
    struct Bet {
        address bettor;
        uint amount;
        uint player_id;
        uint betCoef;
    }

    address private betMaker;
    BoxOracle public oracle;
    uint public minBetAmount;
    uint public maxBetAmount;
    uint public totalBetAmount;
    uint public thresholdAmount;

    Bet[] private bets;
    Player public player_1;
    Player public player_2;

    bool private suspended = false;
    mapping (address => uint) public balances;
    bool public firstCheck = true;
    
    constructor(
        address _betMaker,
        string memory _player_1,
        string memory _player_2,
        uint _minBetAmount,
        uint _maxBetAmount,
        uint _thresholdAmount,
        BoxOracle _oracle
    ) {
        betMaker = (_betMaker == address(0) ? msg.sender : _betMaker);
        player_1 = Player(1, _player_1, 0, 200);
        player_2 = Player(2, _player_2, 0, 200);
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
        thresholdAmount = _thresholdAmount;
        oracle = _oracle;

        totalBetAmount = 0;
    }

    // It executes on calls to the contract with no data (calldata), 
    // e.g. calls made via send() or transfer()
    receive() external payable {}

    // Executed if none of the other functions match the function identifier or 
    // no data was provided with the function call. 
    fallback() external payable {}
    


    // klađenje na pobjedu određenog boksača
    function makeBet(uint8 _playerId) public payable {
        require(msg.sender != betMaker, "Bet maker can not bet");
        require(oracle.getWinner() == 0, "Can not bet after finished");
        require(msg.value > minBetAmount, "Can not bet under min amount");
        require(msg.value < maxBetAmount, "Can not bet over max amount");

        // kladi se 
        bets.push(Bet(msg.sender, msg.value, _playerId, (_playerId == 1 ? player_1.currCoef : player_2.currCoef)));
        _playerId == player_1.id ? player_1.totalBetAmount += msg.value : player_2.totalBetAmount += msg.value;

        // ukoliko je iznos uplaćenih oklada veći od zadanog iznosa potrebno je ažurirati koeficijente.
        if (player_1.totalBetAmount + player_2.totalBetAmount > thresholdAmount) {
            // provjeri odnosi li se cijeli iznos na 1 igraca ako da suspendiraj kladenje 
            if (player_1.totalBetAmount == 0 || player_2.totalBetAmount == 0) {
                suspended = true;
            }
            else {
                // update koef 
                player_1.currCoef = ((player_1.totalBetAmount + player_2.totalBetAmount) * 100) / player_1.totalBetAmount;
                player_2.currCoef = ((player_1.totalBetAmount + player_2.totalBetAmount) * 100) / player_2.totalBetAmount;
            }
        }
        
        totalBetAmount += msg.value;
        balances[msg.sender] += msg.value;
    }

    // povratak uplaćenih sredstava korisnicima ako je mec suspendiran
    function claimSuspendedBets() public {
        require(suspended == true, "Can not claim funds until suspended");
        require(msg.sender != betMaker, "Bet maker can not claim suspended bets");

        // vrati svakom ko se kladio novce 
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    // podizanje dobitka nakon nesuspenidranog zavrsenog meca 
    function claimWinningBets() public {
        require(suspended == false, "Can not claim funds if suspended");
        require(msg.sender != betMaker, "Bet maker can not claim winning funds");
        uint256 winner = oracle.getWinner();
        require(winner != 0, "Can not claim funds before declared winner");
        uint256 sum = 0;

        // odredi kliko svaki msg.sender claima 
        for (uint i = 0; i < bets.length; i++) {
            if (bets[i].bettor == msg.sender && bets[i].player_id == winner) {
                sum += bets[i].amount * bets[i].betCoef;
                player_1.id == winner ? player_1.totalBetAmount -= bets[i].amount : player_2.totalBetAmount -= bets[i].amount;
            }
        }

        // claim
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(sum / 100);
    }

    // nakon sta svi uzmu svoj winning bet vlasnik (bet maker) uzima ostatak i unistava ugovor 
    function claimLosingBets() public {
        require(suspended == false, "Can not claim funds if suspended");
        require(msg.sender == betMaker, "Only bet maker can claim losing bets");
        uint256 winner = oracle.getWinner();
        require(winner != 0, "Can not claim funds before declared winner");

        // bet maker uzima ostatak 
        require(winner == player_1.id ? player_1.totalBetAmount == 0 : player_2.totalBetAmount == 0, "Can not claim losing bets before all winners are paid");
        payable(msg.sender).transfer(address(this).balance);

        // unisti ugovor 
        selfdestruct(payable(address(this)));
    }
}