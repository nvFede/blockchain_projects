// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract crowdfunding {


    uint256 id = 1;

    enum fundRaisingState {
        Open,
        Expired,
        Successful
    }

    struct Project {
        uint256 project_id;
        string name;
        string description;
        address payable author;
        address owner;
        uint fundRaisingGoal;
        uint currentFunds;
        uint expireDate;
        fundRaisingState state;

    }

    Project project;

    mapping (address => uint) public contributions;

    event FundingReceived(address contributor, uint amount, uint currentTotal);

    event NewStateChange(fundRaisingState newState);

    event FundRaisingSuccesfullyCompleted(address recipient);

    // Modifier to check current state
    modifier inState(fundRaisingState _state) {
        require(project.state == _state);
        _;
    }

    modifier isOwner {
        require(
            msg.sender == project.owner,
            "You must be the owner of the project to perform this action."
        );
        _;
    }
    modifier isNotOwner {
        require(
            msg.sender != project.owner,
            "The owner can't perform this action."
        );
        _;
    }

    constructor( string memory _name, string memory _description, uint _fundRaisingGoal, uint _expireDate) {
        project = Project(
            id++,
            _name,
            _description,
            payable(msg.sender),
            msg.sender,
            _fundRaisingGoal,
            0,
            block.timestamp.add(_expireDate.mul(1 days)), // how many days to expire
            fundRaisingState.Open
        );
        //projects.push(project);
    }

    function contribute() external inState(fundRaisingState.Open) payable isNotOwner {

        contributions[msg.sender] = contributions[msg.sender] + msg.value;
        project.currentFunds = project.currentFunds + msg.value;
        emit FundingReceived(msg.sender, msg.value, project.currentFunds);

        //checkIfFundingCompleteOrExpired();
        checkIfFundRaisingExpired();
    }

    /** @dev Function to change the project state depending on conditions.
      */
    function checkIfFundRaisingExpired() public {
        if (project.currentFunds >= project.fundRaisingGoal) {
            project.state = fundRaisingState.Successful;
            payProjectOwner();
        } else if (block.timestamp > project.expireDate)  {
            project.state = fundRaisingState.Expired;
        }
        //completeAt = now;
    }

    function payProjectOwner() internal inState(fundRaisingState.Successful) returns (bool){

        uint256 totalRaised = project.currentFunds;

        project.currentFunds = 0;

        if (project.author.send(totalRaised)) {
            emit FundRaisingSuccesfullyCompleted(project.author);
            return true;
        } else {
            project.currentFunds = totalRaised;
            project.state = fundRaisingState.Successful;
        }

        return false;
    }

    function getProjectDetails() public view returns(
        uint id,
        string memory name,
        string memory description,
        address payable author,
        address owner,
        uint fundRaisingGoal,
        uint currentFunds,
        uint expireDate,
        fundRaisingState state
    ) {
        id = project.project_id;
        name = project.name;
        description = project.description;
        author = project.author;
        owner = project.owner;
        fundRaisingGoal = project.fundRaisingGoal;
        currentFunds = project.currentFunds;
        expireDate = project.expireDate;
        state = project.state;
    }


    function changeName( string memory _name) public isOwner {
         project.name = _name;
    }

    function changeDescription(string memory _description) public isOwner {
        project.description = _description;
    }




}
