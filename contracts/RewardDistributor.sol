// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract RewardDistributor {
    IERC20 public rewardToken;
    uint256 public rewardFactor;
    uint256 public periodLength;
    uint256 public periodStart;

    struct TraderInfo {
        uint256 lastUpdateTime;
        uint256 cumulativeVolume;
        uint256 rewardDebt;
    }

    struct MarketInfo {
        uint256 totalVolume;
        mapping(address => TraderInfo) traders;
    }

    mapping(uint256 => MarketInfo) public markets;

    constructor(address _rewardTokenAddress, uint256 _rewardFactor, uint256 _periodLength) {
        rewardToken = IERC20(_rewardTokenAddress);
        rewardFactor = _rewardFactor;
        periodLength = _periodLength;
        periodStart = block.timestamp;
    }

    function updateVolume(uint256 marketId, uint256 volume) external {
        require(block.timestamp < periodStart + periodLength, "The current period has ended");
        
        MarketInfo storage market = markets[marketId];
        TraderInfo storage trader = market.traders[msg.sender];

        if(trader.lastUpdateTime > 0) {
            claimReward(marketId, msg.sender);
        }

        trader.cumulativeVolume += volume;
        market.totalVolume += volume;
        trader.lastUpdateTime = block.timestamp;
    }

    function claimReward(uint256 marketId, address traderAddress) public {
        require(block.timestamp < periodStart + periodLength, "The current period has ended");

        MarketInfo storage market = markets[marketId];
        TraderInfo storage trader = market.traders[traderAddress];
        uint256 timeElapsed = block.timestamp - trader.lastUpdateTime;
        uint256 weightedVolume = timeElapsed * trader.cumulativeVolume;
        uint256 reward = (weightedVolume * rewardFactor) / market.totalVolume;

        trader.cumulativeVolume = 0;
        trader.lastUpdateTime = block.timestamp;
        trader.rewardDebt += reward;

        require(rewardToken.transfer(traderAddress, trader.rewardDebt), "Transfer failed");
        trader.rewardDebt = 0;
    }

    function startNewPeriod() external {
        require(block.timestamp >= periodStart + periodLength, "The current period has not ended yet");
        periodStart = block.timestamp; // Reset the start time for the new period
    }


    function calculateReward(uint256 marketId, address traderAddress) public view returns (uint256) {
        MarketInfo storage market = markets[marketId];
        TraderInfo storage trader = market.traders[traderAddress];
        uint256 timeElapsed = block.timestamp - trader.lastUpdateTime;
        uint256 weightedVolume = timeElapsed * trader.cumulativeVolume;
        uint256 reward = (weightedVolume * rewardFactor) / market.totalVolume;
        return reward;
    }
}
