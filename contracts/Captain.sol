//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2; // needed to return arrays


contract Captain {
    
    uint MAX_SCORE = 100;
    uint START_SCORE = 80;
    struct User {
        bool active;
        uint solved;
        uint disputes;
        uint[] puzzle_ids;
    }

    struct Puzzle {
        address issuer;
        string puzzle_string;
        string puzzle_desc;
        uint reward;
        uint rating;
        Solution sol;
    }

    struct Solution {
        address solver;
        string result;
        bool solved;
    }

    mapping (address => User) users;
    Puzzle[] puzzles;

    function createUser() public {
        require(!users[msg.sender].active);
        uint[] memory ids;
        users[msg.sender] = User(true, 0, 0, ids);
    }

    modifier userAction {
        require(users[msg.sender].active);
        _;
    }
    
    function postPuzzle(string memory _p_string, string memory _desc, uint _reward,
                        uint _rating) public userAction returns(uint) {
        require(_rating <= MAX_SCORE);
        puzzles.push(Puzzle(msg.sender, _p_string, _desc, _reward, _rating,
                            Solution(address(0), "", false)));
        users[msg.sender].puzzle_ids.push(puzzles.length - 1);
        return puzzles.length - 1;
    }

    function postSolution(string memory _solution, uint _puzzle_id)
        public userAction returns (bool) {
        Puzzle memory p = puzzles[_puzzle_id];
        require(calculateRating(msg.sender) >= p.rating);
        if (p.sol.solved)
            return false;
        puzzles[_puzzle_id].sol = Solution(msg.sender, _solution, true);
        users[msg.sender].solved++;
        return true;
    }

    function disputePuzzle(uint _puzzle_id) public {
        Puzzle memory p = puzzles[_puzzle_id];
        require(msg.sender == p.issuer);
        users[p.sol.solver].disputes++;
    }

    function getPuzzles() public view returns (Puzzle[] memory) {
        return puzzles;
    }

    function calculateRating(address _user) private view returns(uint) {
        User memory user = users[_user];
        if (user.solved < 10)
            return START_SCORE;
        return MAX_SCORE * (1 - user.disputes / user.solved);
    }

    function getUserData() public view userAction returns(User memory) {
        return users[msg.sender];
    }

}
