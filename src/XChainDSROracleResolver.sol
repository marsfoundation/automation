// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IPot {
    function dsr() external view returns (uint256);
}

interface IForwarderBase {
    struct PotData {
        uint96  dsr;  // Dai Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }
    function getLastSeenPotData() external view returns (PotData memory);
}

interface IForwader is IForwarderBase {
    function refresh(uint256 gasLimit) external;
}

interface IForwaderArbitrum is IForwarderBase {
    function refresh(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 baseFee
    ) external payable;
}

contract XChainDSROracleResolver {

    IPot public immutable pot;

    constructor(address _pot) {
        pot = IPot(_pot);
    }

    function checker(address forwarder, uint256 maxDelta, uint256 gasLimit)
        external view
        returns (bool canExec, bytes memory execPayload)
    {
        IForwarderBase.PotData memory potData = IForwarderBase(forwarder).getLastSeenPotData();

        if (potData.dsr != pot.dsr() || block.timestamp >= potData.rho + maxDelta) {
            return (true, abi.encodeCall(IForwader.refresh, (gasLimit)));
        }
    }

    function checkerArbitrumStyle(
        address forwarder,
        uint256 maxDelta,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 baseFee
    )
        external view
        returns (bool canExec, bytes memory execPayload)
    {
        IForwarderBase.PotData memory potData = IForwarderBase(forwarder).getLastSeenPotData();

        if (potData.dsr != pot.dsr() || block.timestamp >= potData.rho + maxDelta) {
            return (true, abi.encodeCall(IForwaderArbitrum.refresh, (gasLimit, maxFeePerGas, baseFee)));
        }
    }

}
