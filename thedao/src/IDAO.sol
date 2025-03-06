// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDAO {
    function newProposal(
        address _recipient,
        uint256 _amount,
        string memory _description,
        bytes memory _transactionData,
        uint256 _debatingPeriod,
        bool _newCurator
    ) external returns (uint256 _proposalID);

    function executeProposal(uint256 _proposalID, bytes memory _transactionData) external returns (bool _success);

    function splitDAO(uint256 _proposalID, address _newCurator) external returns (bool _success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function balanceOf(address _owner) external returns (uint256 balance);

    function vote(uint256 _proposalID, bool _supportsProposal) external returns (uint256 _voteID);

    function getNewDAOAddress(uint256 _proposalID) external returns (address _newDAO);
}
