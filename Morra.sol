pragma solidity >=0.4.22 <0.7.0;

contract Morra {
    
    enum Stage {
        FirstCommit,
        SecondCommit,
        FirstReveal,
        SecondReveal,
        Winnings
    }
    event LogDepositReceived(address player);
    event Draw(string message);
    
    struct player {
        address payable playerAddress;
        uint8 choice;
        uint8 guess;
        bytes32 hashChoice;
        bytes32 hashGuess;
    }
    mapping(address => uint256) balance;
    player[2] players;
    Stage private stage = Stage.FirstCommit;
    
    function encode(uint8 choice, uint8 guess, string calldata password) pure external returns (bytes32, bytes32) {
        require((1 <= choice) && (choice <= 5) && (1 <= guess) && (guess <= 5));
        return (keccak256(abi.encodePacked(choice, password)), keccak256(abi.encodePacked(guess, password)));
    }
    
    function commit(bytes32 hashChoice, bytes32 hashGuess) external {
        uint i;
        if (stage == Stage.FirstCommit) {
            i = 0;
        }
        else if (stage == Stage.SecondCommit) {
            i = 1;
        }
        else { revert("both players have committed");
        }
        players[i] = player(msg.sender, 0, 0, hashChoice, hashGuess);
        if (stage == Stage.FirstCommit) {
            stage = Stage.SecondCommit;
        } else {
            stage = Stage.FirstReveal;
        }
    }
    
    function reveal(uint8 choice, uint8 guess, string calldata password) external payable {
        require(stage == Stage.FirstReveal || stage == Stage.SecondReveal, "not in reveal stage");
        require(msg.value/1e18 == 10);
        if (stage == Stage.FirstReveal) {
            require(msg.sender == players[0].playerAddress, "not your turn");
        }
        balance[msg.sender] += msg.value;
        for (uint i = 0; i < 2; i++) {
            if (players[i].hashChoice == keccak256(abi.encodePacked(choice, password))) {
                players[i].choice = choice;
            }
            if (players[i].hashGuess == keccak256(abi.encodePacked(guess, password))) {
                players[i].guess = guess;
            }
        } if (stage == Stage.FirstReveal) {
            stage = Stage.SecondReveal;
        } else {
            stage = Stage.Winnings;
        } if (stage == Stage.Winnings) {
            bool[2] memory playerCorrect = [false, false];
            for (uint i = 0; i < 2; i++) {
                if (players[i].guess == players[(i + 1) % 2].choice) {
                    playerCorrect[i] = true;
                }
            }if (playerCorrect[0] != playerCorrect[1]) {
                for (uint i = 0; i < 2; i++) {
                    if (playerCorrect[i] == true) {
                        balance[players[i].playerAddress] += (players[i].choice * 1e18) + (players[i].guess * 1e18);
                        balance[players[(i + 1) % 2].playerAddress] -= (players[i].choice * 1e18) + (players[i].guess * 1e18);
                    }
                }
            } else {
                emit Draw("It is a draw");
            } stage = Stage.FirstCommit;
        }
    }
    
    function withdraw() external {
        uint256 b = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.transfer(b);
    }
    
    receive() external payable {
        require(msg.data.length == 0);
        emit LogDepositReceived(msg.sender); 
    }
}