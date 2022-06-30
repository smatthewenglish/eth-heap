//SPDX-License-Identifier: GPL-3.0-or-later
// Shoutout Zac Mitton! @VoltzRoad
pragma solidity 0.8.x;

library Heap {

  struct Data {
      Node[] nodes; // root is index 1; index 0 not used
      mapping(uint256 => uint256) indices; // unique id => node index
  }

  struct Node {
      uint256 tokenId;
      int256 priority;
  }

  uint constant ROOT_INDEX = 1;

  //call init before anything else
  function init(Data storage self) internal{
    self.nodes.push(Node(0,0));
  }

  function insert(Data storage self, int256 priority, uint256 tokenId) internal returns(Node memory) {
    require(!isNode(getById(self, tokenId)), "exists already");

    int256 minimize = priority * -1;

    Node memory n = Node(tokenId, minimize);
    
    self.nodes.push(n);
    _bubbleUp(self, n, self.nodes.length-1);

    return n;
  }

  function extractMax(Data storage self) internal returns(Node memory){
    return _extract(self, ROOT_INDEX);
  }

  function extractById(Data storage self, uint256 tokenId) internal returns(Node memory){
    return _extract(self, self.indices[tokenId]);
  }

  //view
  function dump(Data storage self) internal view returns(Node[] memory){
    //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
    return self.nodes;
  }

  function getById(Data storage self, uint256 tokenId) internal view returns(Node memory){
    return getByIndex(self, self.indices[tokenId]);//test that all these return the emptyNode
  }

  function getByIndex(Data storage self, uint256 i) internal view returns(Node memory){
    return self.nodes.length > i ? self.nodes[i] : Node(0,0);
  }

  function getFloorNode(Data storage self) internal view returns(Node memory){
    Node memory node = getByIndex(self, ROOT_INDEX);
    int256 priority = node.priority;
    node.priority  = priority * -1;
    return node;
  }

  function isFloor(Data storage self, uint256 tokenId) internal view returns(bool){
    Node memory node00 = getByIndex(self, ROOT_INDEX);
    Node memory node01 = getByIndex(self, self.indices[tokenId]);
    return node00.tokenId == node01.tokenId;
  }

  function size(Data storage self) internal view returns(uint256){
    return self.nodes.length > 0 ? self.nodes.length-1 : 0;
  }
  
  function isNode(Node memory n) internal pure returns(bool){
    return n.tokenId > 0;
  }

  //private
  function _extract(Data storage self, uint256 i) private returns(Node memory){//√
    if(self.nodes.length <= i || i <= 0){
      return Node(0,0);
    }

    Node memory extractedNode = self.nodes[i];
    delete self.indices[extractedNode.tokenId];

    Node memory tailNode = self.nodes[self.nodes.length-1];
    self.nodes.pop();

    if(i < self.nodes.length){ // if extracted node was not tail
      _bubbleUp(self, tailNode, i);
      _bubbleDown(self, self.nodes[i], i); // then try bubbling down
    }
    return extractedNode;
  }

  function _bubbleUp(Data storage self, Node memory n, uint256 i) private{//√
    if(i == ROOT_INDEX || n.priority <= self.nodes[i/2].priority){
      _insert(self, n, i);
    } else {
      _insert(self, self.nodes[i/2], i);
      _bubbleUp(self, n, i/2);
    }
  }

  function _bubbleDown(Data storage self, Node memory n, uint256 i) private{//
    uint256 length = self.nodes.length;
    uint256 cIndex = i*2; // left child index

    if(length <= cIndex){
      _insert(self, n, i);
    } else {
      Node memory largestChild = self.nodes[cIndex];

      if(length > cIndex+1 && self.nodes[cIndex+1].priority > largestChild.priority ){
        largestChild = self.nodes[++cIndex];// TEST ++ gets executed first here
      }

      if(largestChild.priority <= n.priority){ //TEST: priority 0 is valid! negative ints work
        _insert(self, n, i);
      } else {
        _insert(self, largestChild, i);
        _bubbleDown(self, n, cIndex);
      }
    }
  }

  function _insert(Data storage self, Node memory n, uint256 i) private{//√
    self.nodes[i] = n;
    self.indices[n.tokenId] = i;
  }
}
