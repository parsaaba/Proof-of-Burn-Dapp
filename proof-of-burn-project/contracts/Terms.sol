// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
import "./Ownable.sol";
import "./ChainLinkOracle.sol";
import "./Helper.sol";

contract Terms is Ownable, Helper, ChainLinkOracle {

    event NewEntry(address _address, uint betAmount, uint endDate, uint stepsGoal);
    event resultsReceived(address _address, uint returnedAmount, bool outcome, uint avgHistoricalSteps);
    

    struct Entry {
        uint256 betAmount; //amount participant bets
        uint32 startDate; // when participant made bet 
        string accessToken;
        uint256 stepsGoal;
        uint16 numberOfDays;
        bool activeEntry;
    }
    // This declares a state variable that
    // stores a `Entry` struct for each possible entry.
    mapping(address => Entry) entries;

    // TODO mapping of accessToken to addresses? We need prevent multiple addresses from using the same access token
   

    function makeEntry(string memory _accessToken,uint256 stepsGoal, uint16 numberOfDays) external payable {
        // Check that user does not have a active entry
        // If not, add an entry and add mapping to entries
        require(!entries[msg.sender].activeEntry, "You already have an active entry, only one active entry per participant!");
        require(msg.value > 0, "Please include a bet amount");
        uint32 currentDate = uint32(now);
        entries[msg.sender] = Entry(msg.value, currentDate, _accessToken, stepsGoal, numberOfDays, true);
        emit NewEntry(msg.sender, entries[msg.sender].betAmount, currentDate + entries[msg.sender].numberOfDays, entries[msg.sender].stepsGoal);
    }


    function _buildOuraRequestUrl (uint32 _startDate, uint32 _endDate, string memory _accessToken, uint256 _stepsGoal) private pure returns(string memory){
        string memory a = "https://ea4ank8od6.execute-api.us-east-1.amazonaws.com/default/getOuraRingDataResults?startTimestamp=";
        string memory b = uint2str(_startDate);
        string memory c = "&token=";
        string memory d = _accessToken; 
        string memory e = "&stepsGoal=";
        string memory f = uint2str(_stepsGoal); 
        string memory g = "&endTimestamp="; 
        string memory h = uint2str(_endDate);
        
        return string(abi.encodePacked(a, b, c, d, e, f, g, h));
    }

    function checkResults() external returns(bytes32){
        Entry memory entry = entries[msg.sender];
        // if days for contest + start date is less than today, let them know the contest isn't over yet
        // if days for contest + start date is past the current time, make a call to oracle
        require(entry.startDate + entry.numberOfDays < uint32(now),"Contest has not finished yet");
        string memory url = _buildOuraRequestUrl(entry.startDate, entry.startDate + entry.numberOfDays, entry.accessToken, entry.stepsGoal);
        // delete entries[msg.sender];
        return requestNumberOfDaysMetGoal(url);
    }

}
