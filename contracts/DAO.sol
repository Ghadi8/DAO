// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title DAO
 * @author Ghadi Mhawej
 * @dev only NFT holders of specific project can create and vote on proposals
 */

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 proposalNumber;

    /// @notice valid token IDs that can interact with this contract
    uint256[] public validTokens;

    /// @notice NFT contract address of which holders can interact with this contract
    IdaoContract daoContract;

    /**
     * @notice constructor
     * @param _nftContract contract address of NFT project
     * @param _tokenIDs array of tokens of NFT project that will be eligible to participate in DAO
     **/

    constructor(address _nftContract, uint256[] memory _tokenIDs) {
        owner = msg.sender;
        proposalNumber = 1;
        daoContract = IdaoContract(_nftContract);
        validTokens = _tokenIDs;
    }

    /// @notice general structure of proposal

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    /// @notice event emitted during the creation of a new proposal

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    /// @notice event emitted on new vote

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    /**
     * @notice private function that checks if msg sender is eligible to create a proposal
     * @param _proposer is the address that is being checked for proposal eligibility
     **/

    function checkProposalEligibility(address _proposer)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposer, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice private function that checks if msg sender is eligible to vote for specific proposal
     * @param _id of a specific proposal
     * @param _voter address being checked for voting eligibility of proposal
     **/

    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice creates a new proposal
     * @param _description description of proposal
     * @param _canVote array of addresses eligible to vote on proposal
     **/

    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth Proposals"
        );

        proposal storage newProposal = Proposals[proposalNumber];
        newProposal.id = proposalNumber;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            proposalNumber,
            _description,
            _canVote.length,
            msg.sender
        );
        proposalNumber++;
    }

    /**
     * @notice vote on active proposal
     * @param _id id of proposal to vote on
     * @param _vote user can either vote true or false
     **/

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can not vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this Proposal"
        );

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    /**
     * @notice count votes of specific proposal
     * @param _id id of proposal
     **/

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    /**
     * @notice add token Ids that are eligible to participate in DAO
     * @param _tokenId Ids to be added
     **/

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
}
