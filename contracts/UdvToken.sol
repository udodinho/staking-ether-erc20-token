// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingERC20Token {
    struct Stake {
        uint256 stakingTime;
        uint256 durationInDays;
        uint256 amount;
        uint256 rewards;
        bool isStaked;
    }
    
    address owner;
    mapping (address => uint256) balances;
    mapping (address => Stake[]) stakes;
    address immutable TOKENADDRESS;
    // 0x9a2E12340354d2532b4247da3704D2A5d73Bd189

    constructor(address _tokenAddress) {
        owner = msg.sender;
        TOKENADDRESS = _tokenAddress;
    }

    event StakedSuccessful(address user, uint256 amount);
    event WithdrawSuccessful(address user, uint256 _totalRewards);

    function stakeERCToken(uint256 _amount, uint256 _duration) external payable {
        require(msg.sender != address(0), "you can't stake with an address zero");
        require(_amount > 0, "staking 0 is not allowed");

        uint256 _userBalance = IERC20(TOKENADDRESS).balanceOf(msg.sender);

        require(_amount > _userBalance, "Insufficient balance");

        IERC20(TOKENADDRESS).approve(address(this), _amount);
        IERC20(TOKENADDRESS).transferFrom(msg.sender, address(this), _amount);

        uint256 stakingStart = block.timestamp;

        balances[msg.sender] += _amount;

        Stake memory userStake = Stake({
            stakingTime: stakingStart,
            durationInDays: block.timestamp + (_duration * 1 days),
            amount: _amount,
            rewards: 0,
            isStaked: true
        });

        stakes[msg.sender].push(userStake);
    }

    function withdrawRewards(uint256 _amount, uint256 _stakeId) external {
        require(msg.sender != address(0), "You can't withdraw with address zero");
        require(_stakeId < stakes[msg.sender].length, "Invalid stake ID");

        Stake storage staker = stakes[msg.sender][_stakeId];
        require(staker.isStaked, "Stake not active");
        
        uint256 _totalRewards;

        require(balances[msg.sender] < _amount, "Insufficient funds");

        if (block.timestamp > staker.stakingTime + staker.durationInDays) {
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
        uint256 duration = block.timestamp - staker.durationInDays;
        uint256 interestRatePerYear = 5 * 1e5; // 5% interest per year

        uint256 interest = (staker.amount * interestRatePerYear * duration) / (365 days * 1e5);
        return interest;
    }

    function getContractBalance() external view returns (uint256) {
        onlyOwner();
        return address(this).balance;
    }

    function getStake() external view returns (Stake[] memory) {
        return stakes[msg.sender];
    }

    function getStake(uint256 _stakeId) external view returns (Stake memory) {
        return stakes[msg.sender][_stakeId];
    }

    function isUserStaked(uint256 _stakeId) external view returns (bool) {
        return stakes[msg.sender][_stakeId].isStaked;
    }

    function onlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }
}
