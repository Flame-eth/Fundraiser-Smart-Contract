// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CrowdFunding {

    mapping(address=>uint)public donators;
    address public manager;
    uint public minimumDonation;
    uint public deadline;
    uint public target;
    uint public totalRaisedAnount;
    uint public totalNoOfDonators;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping (uint=>Request)public requests;
    uint public numRequests;

    constructor (uint _targetAmount, uint _deadline){
        target=_targetAmount;
        minimumDonation=block.timestamp+_deadline;
        minimumDonation=100 wei;
        manager=msg.sender;
    }

    function sendEth()public payable {
        require (block.timestamp < deadline, "Deadline has passed");
        require (msg.value >= minimumDonation, "Minimum Donation not met");

        if(donators[msg.sender]==0){
            totalNoOfDonators++;
        }
        donators[msg.sender]+=msg.value;
        totalRaisedAnount+=msg.value;
    }

    function getContractBalance()public view returns(uint){
        return address(this).balance;   
    }

    function refund()public{
        require(block.timestamp>deadline && totalRaisedAnount<target, "You are not eligible to withdraw");
        require(donators[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(donators[msg.sender]);
        donators[msg.sender]=0;
    }

    modifier onlyManager() {
        require (msg.sender==manager, "Only manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipeint, uint _value)public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipeint;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;   
    }

    function voteRequest(uint _requestNo)public {
        require(donators[msg.sender]>0, "You must be a donator");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false, "You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo)public onlyManager {
        require (totalRaisedAnount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false, "The request has been completed");
        require(thisRequest.noOfVoters > totalNoOfDonators/2, "Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;

    }


}