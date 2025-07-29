// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundingRF {
    struct ResearchCampaign {
        address owner;
        string title;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        uint256 amountCollected;
        string imageURL;
        address[] donators;
        uint256[] donations;
        bool isActive;
    }

    mapping(uint256 => ResearchCampaign) public RCampaigns;
    uint256 public numRCampaigns = 0;

    event ResearchCampaignCreated(uint256 id, address owner, string title, uint256 targetAmount, uint256 deadline);
    event DonationReceived(uint256 id, address donator, uint256 amount);
    event CampaignStopped(uint256 id, string reason);
    event FundsWithdrawn(uint256 id, address owner, uint256 amount);

    function createResearchCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _targetAmount,
        uint256 _deadline,
        string memory _imageURL
    ) public returns (uint256) {
        ResearchCampaign storage newResearchCampaign = RCampaigns[numRCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a future date.");
        require(_targetAmount > 0, "Target amount must be greater than 0.");

        newResearchCampaign.owner = _owner;
        newResearchCampaign.title = _title;
        newResearchCampaign.description = _description;
        newResearchCampaign.targetAmount = _targetAmount;
        newResearchCampaign.deadline = _deadline;
        newResearchCampaign.amountCollected = 0;
        newResearchCampaign.imageURL = _imageURL;
        newResearchCampaign.isActive = true;

        uint256 campaignId = numRCampaigns;
        numRCampaigns++;

        emit ResearchCampaignCreated(campaignId, _owner, _title, _targetAmount, _deadline);
        return campaignId;
    }

    function donateToResearchCampaign(uint256 _id) public payable {
        require(_id < numRCampaigns, "Campaign does not exist.");
        ResearchCampaign storage researchCampaign = RCampaigns[_id];

        require(researchCampaign.isActive, "Campaign is not active.");
        require(msg.value > 0, "Donation must be greater than zero.");
        require(researchCampaign.deadline > block.timestamp, "Campaign has ended.");

        require(researchCampaign.amountCollected < researchCampaign.targetAmount, "Target already met.");

        (bool sent,) = payable(researchCampaign.owner).call{value: msg.value}("");
        require(sent, "Fund transfer failed.");

        researchCampaign.donators.push(msg.sender);
        researchCampaign.donations.push(msg.value);
        researchCampaign.amountCollected += msg.value;

        emit DonationReceived(_id, msg.sender, msg.value);
        if (researchCampaign.amountCollected >= researchCampaign.targetAmount) {
            researchCampaign.isActive = false;
            emit CampaignStopped(_id, "Target reached.");
        }
    }

    function withdrawFunds(uint256 _id, uint256 _amount) public {
        require(_id < numRCampaigns, "Campaign does not exist.");
        ResearchCampaign storage researchCampaign = RCampaigns[_id];

        require(msg.sender == researchCampaign.owner, "Not campaign owner.");
        require(_amount > 0, "Withdrawal amount invalid.");
        require(researchCampaign.amountCollected >= _amount, "Insufficient funds.");

        (bool sent,) = payable(researchCampaign.owner).call{value: _amount}("");
        require(sent, "Withdrawal failed.");

        researchCampaign.amountCollected -= _amount;
        emit FundsWithdrawn(_id, msg.sender, _amount);
    }

    function getResearchCampaignDonators(uint256 _id) view public returns (address[] memory donators_, uint256[] memory donations_) {
        require(_id < numRCampaigns, "Campaign does not exist.");
        return (RCampaigns[_id].donators, RCampaigns[_id].donations);
    }

    function getResearchCampaign(uint256 _id) view public returns (
        address owner,
        string memory title,
        string memory description,
        uint256 targetAmount,
        uint256 deadline,
        uint256 amountCollected,
        string memory imageURL,
        bool isActive
    ) {
        require(_id < numRCampaigns, "Campaign does not exist.");
        ResearchCampaign storage campaign = RCampaigns[_id];
        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.targetAmount,
            campaign.deadline,
            campaign.amountCollected,
            campaign.imageURL,
            campaign.isActive
        );
    }

    function getNumResearchCampaigns() view public returns (uint256) {
        return numRCampaigns;
    }

    function stopResearchCampaign(uint256 _id) public {
        require(_id < numRCampaigns, "Campaign does not exist.");
        ResearchCampaign storage researchCampaign = RCampaigns[_id];
        require(msg.sender == researchCampaign.owner, "Not campaign owner.");
        require(researchCampaign.isActive, "Campaign is not active.");

        researchCampaign.isActive = false;
        emit CampaignStopped(_id, "Manually stopped by owner.");
    }
}