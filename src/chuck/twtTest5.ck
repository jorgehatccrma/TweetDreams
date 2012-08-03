// twtTest5.ck
//
// A script for sending OSC messages to test twtSynthControl.ck
// Created by Luke Dahl 5/15/10 from twtTest.ck

// this file iteratively make fake nodes and trees
// it is a simplified approximation of real performance


8890 => int out_port;
"localhost" => string hostname;

OscSend osc_out;
osc_out.setHost( hostname, out_port );

20 => int numTrees;   // number of trees to make
6 => int nodesPerTree;  // number of tweets per tree
0 => int gTestDebug;

0 => int nodeNum;
0 => int echoID;
for (0 => int tree; tree < numTrees; tree++)
{
    if( gTestDebug )
        <<< "twtTest5: New tree ", tree >>>;
    
    // create 1st node for the tree ----------------------------------------------
    // send a newNode message, with neighbor 0
    1 +=> nodeNum;
    nodeNum => int firstNodeInTree;
    nodeNum + "" => string name;
    osc_out.startMsg( "/twt/newNode, s s f s i");
    name => osc_out.addString;              // nodeID
    "0" => osc_out.addString;              // neighbor nodeID
    0.5 => osc_out.addFloat;               // distance
    "this is tweet "+ nodeNum + " on tree " + tree => osc_out.addString;   // message
    Std.rand2(0,1) => osc_out.addInt;                   // isLocal?
   
    // trigger node
    0 => int hopLvl;
    0.0 => float del;
    osc_out.startMsg( "/twt/triggerNode", "i s f i");
    echoID++;
    if( echoID > 99 ) 0=> echoID;
    echoID => osc_out.addInt;              // echoID
    name => osc_out.addString;              // nodeID
    del => osc_out.addFloat;                // delay in ms
    hopLvl => osc_out.addInt;              // hopLevel
    
    Std.rand2(500, 3000)*1::ms => now;
  
    for (1 => int i; i < nodesPerTree; i++)
    {
        // create a new node
        1 +=> nodeNum;
        nodeNum + "" => string name;
        nodeNum-1 + ""=> string name2;
        osc_out.startMsg( "/twt/newNode, s s f s i");
        name => osc_out.addString;             // nodeID
        name2 => osc_out.addString;            // neighbor nodeID
        0.5 => osc_out.addFloat;               // distance
        "this is tweet "+ nodeNum + " on tree " + tree => osc_out.addString;   // message
        Std.rand2(0,1) => osc_out.addInt;                   // isLocal?
        
        if( gTestDebug )
            <<< "twtTest5 send newNode: ", name >>>;
        
        // trigger node
        0 => int hopLvl;
        0.0 => float del;
        osc_out.startMsg( "/twt/triggerNode", "i s f i");
        echoID++;
        if( echoID > 99 ) 0=> echoID;
        echoID => osc_out.addInt;              // echoID
        name => osc_out.addString;              // nodeID
        del => osc_out.addFloat;          // delay in ms
        hopLvl => osc_out.addInt;              // hopLevel
        
        if( gTestDebug )
            <<< "twtTest5 trigger node: ", nodeNum >>>;
        
        
        // trigger earlier nodes in "tree"
        0 => del;
        250.0 => float delInc;
        for ( nodeNum-1 => int j; j >= firstNodeInTree; j--)
        {
            // trigger node
            1 +=> hopLvl;
            delInc +=> del;
            osc_out.startMsg( "/twt/triggerNode", "i s f i");
            echoID => osc_out.addInt;              // echoID
            j + "" => name;
            name => osc_out.addString;              // nodeID
            del => osc_out.addFloat;          // delay in ms
            hopLvl => osc_out.addInt;              // hopLevel
            
            if( gTestDebug )
                <<< "twtTest5 trigger node: ", name >>>;
         }
        // wait before new tweet arrives
        Std.rand2(500, 3000)*1::ms => now;
    }
    
    // wait for new tree
    Std.rand2(700, 3000)*1::ms => now;

}









