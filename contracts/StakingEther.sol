// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract StakingEther {
    struct Stake {
        uint256 stakingTime;
        uint256 durationInSeconds;
        uint256 amount;
        uint256 rewards;
        bool isStaked;
    }
    
    address owner;
    mapping(address => Stake[]) stakes;

    constructor() {
        owner = msg.sender;
    }

    event StakedSuccessful(address indexed user, uint256 indexed amount);
    event WithdrawSuccessful(address indexed user, uint256 indexed _totalRewards);

    function stake(uint256 _duration) external payable {
        require(msg.sender != address(0), "you can't stake with an address zero");
        require(msg.value > 0, "staking 0 is not allowed");

        uint256 stakingStart = block.timestamp;

        Stake memory userStake = Stake({
            stakingTime: stakingStart,
            durationInSeconds: _duration * 30 days,
            amount: msg.value,
            rewards: 0,
            isStaked: true
        });

        stakes[msg.sender].push(userStake);

        emit StakedSuccessful(msg.sender, msg.value);
    }

    function withdrawRewards(uint256 _stakeId) external {
        require(msg.sender != address(0), "You can't withdraw with address zero");
        require(_stakeId < stakes[msg.sender].length, "Invalid stake ID");

        Stake storage staker = stakes[msg.sender][_stakeId];
        require(staker.isStaked, "Stake not active");
        
        uint256 _totalRewards;

        if (block.timestamp > staker.stakingTime + staker.durationInSeconds) {
            _totalRewards = staker.amount + calculateInterestRate(msg.sender, _stakeId);
        } else {
            _totalRewards = staker.amount;
        }

        staker.isStaked = false;
        staker.rewards = _totalRewards;
        staker.amount = 0;


        require(address(this).balance >= _totalRewards, "Insufficient contract balance for withdrawal");

        (bool sent, ) = msg.sender.call{value: _totalRewards}("");
        require(sent, "Withdrawal failed!");

        emit WithdrawSuccessful(msg.sender, _totalRewards);
    }

    function calculateInterestRate(address _user, uint256 _stakeId) private view returns (uint256) {
        Stake storage staker = stakes[_user][_stakeId];
        uint256 duration = block.timestamp - staker.stakingTime;
        uint256 interestRatePerYear = 5 * 1e18; // 5% interest per year

        uint256 interest = (staker.amount * interestRatePerYear * duration) / (365 days * 1e18);
        return interest;
    }

    function getContractBalance() external view returns (uint256) {
        onlyOwner();
        return address(this).balance;
    }

    function getStake() external view returns (Stake[] memory) {
        return stakes[msg.sender];
    }

    function getStake(uint256 _stakeId) external view returns (Stake[] memory) {
        require(msg.sender != address(0), "Address zero not allowed");
        require(_stakeId < stakes[msg.sender].length, "Invalid stake ID");

        return stakes[msg.sender];
    }

    function isUserStaked(uint256 _stakeId) external view returns (bool) {
        require(_stakeId < stakes[msg.sender].length, "Invalid stake ID");

        return stakes[msg.sender][_stakeId].isStaked;
    }

    function onlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }
}
