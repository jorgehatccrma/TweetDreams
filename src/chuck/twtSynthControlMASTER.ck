// twtSynthControlMASTER.ck
//
// Recieves OSC messages from python and sends messages to chuck clients
// and processing
//
//   Created by Luke Dahl from twtSynthControl, 5/26/10

// globals for tracking terms & queue times
//[ "musica", "amore", "cappuccino", "technology", "politics" ] @=> string gTerms[];
// [ "#modulations", "music", "technology", "participate"  ] @=> string gTerms[];
// [ "make", "music", "technology", "participate"  ] @=> string gTerms[];
// [ "social", "innovation", "numbers", "art", "music" ] @=> string gTerms[];
[ "music", "technology", "data", "participation", "play"  ] @=> string gTerms[];

gTerms.cap() => int gNumTerms;
[ 0, 0, 0, 0, 0, 0, 0, 0] @=> int gTermsIn[];  // whether a term is in (1) or out (0)
//"#TweetDreams" => string gKeyword;
//"#TEDxSV" => string gKeyword;
//"#Modulations" => string gKeyword;
//"#makerfaire" => string gKeyword;
//"#NIME2011" => string gKeyword;
"#CCRMA" => string gKeyword;


// networking globals ==============================================================================
["localhost" ] @=> string clients[];  // computers running chuck clients
clients.cap() => int gNumClients;

//"localhost" => string proc_client;                // address ofcomputer running processing
//"localhost" => string pyth_server;                // address of computer running python
//"10.10.10.50" => string proc_client;                // address ofcomputer running processing
"192.168.181.194" => string proc_client;                // address ofcomputer running processing
"localhost" => string pyth_server;                // address of computer running python

//if( me.args() > 1 )
//{   // command line arguments used to give ip addresses of other computers
//    me.arg(0) => pyth_server;
//    me.arg(1) => proc_client;
//}
<<<"twtSynthControlMASTER: python computer address: ", pyth_server >>>;
<<<"twtSynthControlMASTER: proc computer address: ", proc_client >>>;

// ports: 
8888 => int pyth_port;  // messages to python
8890 => int in_port;    // messages from python
8889 => int out_port;   // messages to chuck clients
8891 => int proc_port;  // messages to processing

// osc receivers:
OscRecv osc_in;
in_port => osc_in.port;
osc_in.listen();
osc_in.event( "/twt/newNode", "s s f s i" ) @=> OscEvent newNodeEvent;
osc_in.event( "/twt/triggerNode", "i s f i" ) @=> OscEvent triggerNodeEvent;

// osc outs
OscSend osc_out;
OscSend osc_proc_out;                     // for messages to processing
osc_proc_out.setHost(proc_client, proc_port);
OscSend osc_pyth_out;                     // for messages to python
osc_pyth_out.setHost(pyth_server, pyth_port);

// setup midi
0 => int device;                         // number of the device to open (see: chuck --probe)
MidiIn midiIn;
MidiMsg msg;
if( !midiIn.open( device ) )
    <<< "WARNING no MIDI device found with number ", device>>>;
else
    <<< "MIDI device:", midiIn.num(), " -> ", midiIn.name() >>>;

666 => int g_prev_new_mel;   // keep track of the most recent new tree melody to avoid repeats

// a class for keeping track of node data ============================================================
public class twtNodeData
{
    // statics ----------------------------------------------------------
    6 => static int numSeqSteps;      // duplicate data... also in twtNodeSynth
    999 => static int noNoteCode;     // duplicate data... also in twtNodeSynth
    
    // public members ---------------------------------------------------
    string msgStr;
    int treeNum;                     // which tree this is part of
    int clientNum;                   // which client is playing this node
    string nodeID;
    int isLocal;
    float mFirstHopTime;             // how much time 'til the first hop trigger, in msec
    float mHopTime;                  // time between subsequent hops, in msec            
    
    int noteSeq[numSeqSteps];
    int wavNum;                      // which wavetable to use
    int modeNum;                     // which mode to use
    float fltFrqRto;                 // a ratio between 0.1 and 8., or so. cutoff as a ratio of fundamental
    float fltQ;
    float panLR;                       // 0 is straight ahead, +-1.0 is behind (+ to the right, - to the left.)
    int dcyTcks;                     // number of ticks that the envelope decays by
    int attTcks;                     // number of ticks that for the envelope to attack
    int stepTcks;                    // number of ticks in a note
    
    // public methods ---------------------------------------------------
    
    // initialize node:
    public void init( string id_str, int wav_num, int mode_num, float flt_frq_ratio, float flt_Q, int dcy_ticks, int att_ticks, int note_ticks, float pan )
    {
        // set member vars
        id_str => nodeID;
        wav_num => wavNum;
        mode_num => modeNum;
        flt_frq_ratio => fltFrqRto;
        flt_Q => fltQ;
        pan => panLR;
        dcy_ticks => dcyTcks;
        att_ticks => attTcks;
        note_ticks => stepTcks;        
    }
    
    // set the note sequence:
    public void setNoteSeq( int seq[] )
    {
        for( 0 => int i; i < numSeqSteps; i++ )
        {
            seq[i] => noteSeq[i];
        }
    }
    
    // set a specific note in the sequence:
    public void setNoteSeqAtIndex( int val, int ind )
    {
        val => noteSeq[ ind ];
    }
    
    // get a specific note in a sequence:
    public int getNoteSeqAtIndex( int ind )
    {
        return noteSeq[ ind ];
    }
}



// globals for sound generation ==================================================================
0 => int gMasterDebug;        // turns on and off debug messages
0.3 => float gRootPanVar;       // amount of randomness in root node pans
0.15 => float gPanVar;           // amount of randomness in child node pans
0.1 => float gPanBias;          // amount of directional bias in child node pans
1 => int gPlayLocal;            // whether or not to play the extra local sound

// node data:
twtNodeData synthArray[1];

0 => int gNextTreeNum;
0 => int gNextClient;

// for wav:
12 => int gNumWavFiles;                                      // this is the number of wav files for normal playback
0 => int gWavNum; 0 => int gMinWavNum; 0 => int gMaxWavNum;  // these are used to set the wav file for the next tree

// for mode:
0 => int gModeNum;
4 => int gNumModes;                    // this is the number of possible modes in twtNodeSynth. // duplicate data... also in twtNodeSynth

// for master dry level
1.0 => float gDryLvl;

// for python dequeue time
2.0 => float gMinQueueTime;  // in seconds
5.5 => float gMaxQueueTime;
0.1 => float gMinLocQueueTime;  // in seconds
0.3 => float gMaxLocQueueTime;
0.15 => float    gTreeThresh; // threshold for new trees


// for melody:
twtNodeData.noNoteCode => int nonote; 
[ [0, -1, nonote, 4, nonote, nonote],    [4, 5, nonote, 0, nonote, nonote],      [5, 5, 4, nonote, nonote, nonote], 
  [2, 2, nonote, 1, nonote, 0],          [-1, nonote, -1, nonote, -1, 0],        [2, 3, 4, 2, nonote, nonote],
  [1-7, nonote, 5-7, 4-7, nonote, 1-7] , [-1-7, nonote, nonote, 1-7, 0, nonote] ,[4, nonote, 0, nonote, nonote, nonote] ,
  [1, nonote, nonote, 2, nonote, nonote]  ] @=> int seqArray[][]; 
10 => int gNumSeqs;
1 => int gSeqNum; 0 => int gMinSeqNum;  2 => int gMaxSeqNum;

// for timing:
12 => int d1;    // ticks per note in section 1
10 => int d2;    // ticks per note in section 2
5 => int d3;
10 => int t1;    // tick time
5 => int t2;     // 1/2 tick time

// WARNING: note_ticks MUST be greater than attack_ticks. ideally it would be greater than attack_ticks + 0.5 decay_ticks                    
[d1*5*t1, d2*5*t1, d2*5*t2, d2*5*t2, d2*2*5*t2, d2*5*t1, d2*5*t1 ] @=> int gFirstHopTimes[];  // units of msec
[d1*5*t2, d2*5*t2, d2*5*t2, d2*5*t2, d2*2*5*t2, d2*5*t2, d2*5*t2 ] @=> int gHopTimes[];       // units of msec
[d1,      d2,      d2,      d3,      d2*2,    d2,      d2      ] @=> int gStepTimes[];      // units of ticks, which is set in twtNodeSynth2.ck to 10msec
[1,       1,       1,       1,       1,       1,       4       ] @=> int gAttTimes[];       // units of ticks, which is set in twtNodeSynth2.ck to 10msec
// 0      1        2        3        4        5        6        
//slow,   fast,    fst hp,  dblx,    hlfx,    slw hp,  slw att
7 => int gNumTimes;
0 => int gTimeNum;


//[20,  10,  20,  30,  40,  50,  50  ] @=> int gDecTimes[]; 
[10, 10, 30, 30,  
 30, 20, 35, 30,
 20, 35, 35, 10,
 10, 10  ] @=> int gDecTimes[]; // these now depend on the wav

[ 10.,  23., 23., 23.,  
  23., 23., 23., 23.,
 10., 23., 23., 7.,
 23., 23.  ] @=> float gFltRatios[]; // these now depend on the wav
 
 [ "sine",       "sineesque", "squaresque1", "sawesque1", // 0-2
  "tonenoise1", "belly1",    "beow1",        "blip1",
  "filtnois1",  "kick1",     "zap1",      "dignois1",
  "bell1.aif",  "suck2" ] @=> string gWavNames[];


//echo streams:
100 => int numEchoStreams;
time echoStartTime[numEchoStreams];
for( 0 => int i; i < numEchoStreams; i++) now => echoStartTime[i]; 
                  

// Do that stuff! ============================================================================

//spork listeners 
spork ~ keyboard();
spork ~ newNodeListener();
spork ~ triggerNodeListener();

// start time varying and midi control (for installation version)
spork ~varyWav();
spork ~varySeq();
// spork ~ midiCtl();

// send initial messages: --------------------------
// send keyword to processing & python
osc_proc_out.startMsg("/twt/keyword", "s");
gKeyword => osc_proc_out.addString;
osc_pyth_out.startMsg("/twt/keyword", "s");
gKeyword => osc_pyth_out.addString;

// send initial dequeue times and threshold
sendQueueTimes(0);
sendQueueTimes(1);
sendThreshold();

// make time 
<<< "twtSynthControlMaster: Here we go..........", "">>>;
while( 1 )
{
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 1 Minute! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 2 Minutes! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 3 Minutes! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 4 Minutes! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 5 Minutes! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 6 Minutes! Let's End This!!!!!!!!!!!!", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 7 Minute! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 8 Minutes! ", "">>>;
    1::minute => now;
    <<< "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9 Minutes!  Gettin pretty late! ", "">>>;
}


// functions ============================================================================
//fun void setSynthStatics( int time_msec, float tuning_ratio )
fun void setSynthStatics()
{
    for(0 => int i; i < gNumClients; i++)
    {
       osc_out.setHost( clients[i], out_port );
       osc_out.startMsg( "/twt/setSynthStatics, i i f");
       //time_msec => osc_out.addInt;
       //tuning_ratio => osc_out.addFloat;  
       
       // send playLocal
       1 => osc_out.addInt;
       gPlayLocal => osc_out.addInt;
       0. => osc_out.addFloat;
    }
}

// sends the actual new node message to processing and the next chuck client
fun void sendNewNode(string nodeID)
{     
    // send to the correct client   
    osc_out.setHost( clients[ synthArray[nodeID].clientNum ], out_port );
    osc_out.startMsg( "/twt/newLocalNode, s s i i i f f i i i i i i i i i f");
    nodeID => osc_out.addString;                       // nodeID
    synthArray[nodeID].msgStr => osc_out.addString;                    // the tweet
    synthArray[nodeID].wavNum => osc_out.addInt;       // wavetable number
    synthArray[nodeID].modeNum => osc_out.addInt;      // mode number
    synthArray[nodeID].isLocal => osc_out.addInt;      // is local
    synthArray[nodeID].fltFrqRto => osc_out.addFloat;  // filter frequency ratio
    synthArray[nodeID].fltQ => osc_out.addFloat;       // filter Q
    synthArray[nodeID].dcyTcks => osc_out.addInt;      // ticks in envelope decay
    synthArray[nodeID].attTcks => osc_out.addInt;      // ticks in envelope attack
    synthArray[nodeID].stepTcks => osc_out.addInt;     // ticks for each note 
    synthArray[nodeID].getNoteSeqAtIndex(0) => osc_out.addInt;     // note sequence 
    synthArray[nodeID].getNoteSeqAtIndex(1) => osc_out.addInt;     // note sequence 
    synthArray[nodeID].getNoteSeqAtIndex(2) => osc_out.addInt;     // note sequence 
    synthArray[nodeID].getNoteSeqAtIndex(3) => osc_out.addInt;     // note sequence 
    synthArray[nodeID].getNoteSeqAtIndex(4) => osc_out.addInt;     // note sequence 
    synthArray[nodeID].getNoteSeqAtIndex(5) => osc_out.addInt;     // note sequence     
    synthArray[nodeID].panLR => osc_out.addFloat;       // pan     
}


// processes ============================================================================

// slowly vary the wave number
fun void varyWav()
{
    while( 1 ) {
        20::second => now;
        //5::second => now;
        incdecWavs( 1, 1);
    }
}    

// slowly vary the sequence (melody) number
fun void varySeq()
{
    while( 1 ) {
        25::second => now;
        //5::second => now;
        incdecSeqs( 1, 1);
    }
}    
   

// process newNode messages -------------------------------------------------
fun void newNodeListener()
{  
     while( 1 )
    {
        newNodeEvent => now;
        
        while( newNodeEvent.nextMsg() )
        {
            newNodeEvent.getString() => string nodeID;
            newNodeEvent.getString() => string neighborID;
            newNodeEvent.getFloat() => float distance;
            newNodeEvent.getString() => string msgString;
            newNodeEvent.getInt() => int isLoc;
            
            if( gMasterDebug )
                <<< "MASTER: newNode message received. ID:", nodeID, " neighbor:", neighborID, " dist:", distance >>>;
            
            // if this node has never been made before...it may have been instantiated if a trigger arrived before this message
            if( synthArray[nodeID] == NULL )
            {
                // initialize new node
                twtNodeData a @=> synthArray[ nodeID ]; 
            }
            
            //if( isLoc )
            //    <<< "LOCAL tweet!", "">>>;
            
            // if this is the first node in a tree...
            if ( neighborID == "0")
            {
                // initialize new node
                Std.rand2( gMinWavNum, gMaxWavNum ) => int tempWavNum;
                Std.rand2f( -gRootPanVar, gRootPanVar ) => float tempPan;
                
 //             synthArray[ nodeID ].init( nodeID, tempWavNum, gModeNum, 6., 1., gDecTimes[gTimeNum], gAttTimes[gTimeNum], gStepTimes[gTimeNum]  );
                synthArray[ nodeID ].init( nodeID, tempWavNum, gModeNum, gFltRatios[tempWavNum], 1., gDecTimes[tempWavNum], gAttTimes[gTimeNum], gStepTimes[gTimeNum], tempPan  );
                msgString => synthArray[ nodeID ].msgStr;
                                
                int seq[];
                Std.rand2( gMinSeqNum, gMaxSeqNum ) => int tempSeqNum; 
                
                // NEW STUFF HERE - if the melody is a repeat draw again
                0 => int temp_draws;
                while((g_prev_new_mel == tempSeqNum) && (temp_draws < 5))
                {
                    Std.rand2( gMinSeqNum, gMaxSeqNum ) => tempSeqNum; 
                    temp_draws++;
                }
                tempSeqNum => g_prev_new_mel; 
                
                seqArray[ tempSeqNum ] @=> seq;
                
                            
                synthArray[ nodeID ].setNoteSeq( seq );   
                
                gFirstHopTimes[ gTimeNum ] => synthArray[ nodeID ].mFirstHopTime;
                gHopTimes[ gTimeNum ] => synthArray[ nodeID ].mHopTime;
  
                gNextTreeNum => synthArray[ nodeID ].treeNum;
                gNextClient => synthArray[ nodeID ].clientNum;
                isLoc => synthArray[ nodeID ].isLocal;
                
                gNextClient++;
                if( gNextClient >= gNumClients ) 0 => gNextClient;
                gNextTreeNum++;                       

 //               if( gMasterDebug )
                    <<< "new tree: wav:", gWavNames[tempWavNum], "mel:", tempSeqNum, "time:", gTimeNum, "mode:", gModeNum >>>;
            }
            // subsequent nodes in a tree....
            else                                         
            {             
                // init( id, wav_num, mode_num, flt_frq_ratio, float flt_Q, decay_ticks, attack_ticks, note_ticks ) 
                
                // calc pan
                float tempPan;
                if( synthArray[ neighborID ].panLR > 0)
                {
                    synthArray[ neighborID ].panLR + gPanBias + Std.rand2f(-gPanVar, gPanVar) => tempPan;
                }
                else
                {
                    synthArray[ neighborID ].panLR - gPanBias + Std.rand2f(-gPanVar, gPanVar) => tempPan;
                }

                synthArray[ nodeID ].init( nodeID, synthArray[neighborID].wavNum, synthArray[neighborID].modeNum, synthArray[neighborID].fltFrqRto, synthArray[neighborID].fltQ, synthArray[neighborID].dcyTcks, synthArray[neighborID].attTcks, synthArray[neighborID].stepTcks, tempPan);           
                msgString => synthArray[ nodeID ].msgStr;   
                setSeqForNewNode( nodeID, neighborID);
                synthArray[ neighborID ].treeNum => synthArray[ nodeID ].treeNum;
                synthArray[ neighborID ].clientNum => synthArray[ nodeID ].clientNum;
                isLoc => synthArray[ nodeID ].isLocal;
                synthArray[ neighborID ].mFirstHopTime => synthArray[ nodeID ].mFirstHopTime;
                synthArray[ neighborID ].mHopTime => synthArray[ nodeID ].mHopTime;              
            }
            
            // send message to processing
            osc_proc_out.startMsg( "/twt/newNode, s s f s i");        // TODO: add isLocal
            nodeID => osc_proc_out.addString;                       // nodeID
            neighborID => osc_proc_out.addString;
            distance => osc_proc_out.addFloat;
            msgString => osc_proc_out.addString;
            isLoc => osc_proc_out.addInt;
          
            // send message to chuck client
            sendNewNode( nodeID );
        }
    }
}

// process triggerNode messages -------------------------------------------------
fun void triggerNodeListener()
{
    while( 1 )
    {
        triggerNodeEvent => now;
        while( triggerNodeEvent.nextMsg() )
        {
            triggerNodeEvent.getInt() => int echoID;
            triggerNodeEvent.getString() => string nodeID;
            triggerNodeEvent.getFloat() => float delayMsec;
            triggerNodeEvent.getInt() => int hopLevel; 
           
            
            // calculate hop times here (this will no longer occur in python) // TODO
            if( hopLevel == 0)
                0 => delayMsec;
            else {
                synthArray[nodeID].mFirstHopTime + (hopLevel-1)*synthArray[nodeID].mHopTime => delayMsec;
            }
            
            if( gMasterDebug ) 
                   
                <<< "MASTER: triggerNode message received. echoID:", echoID, " nodeID:", nodeID, " time:", delayMsec, " hopLevel:", hopLevel  >>>;
        
            // Error checking: if we somehow missed this new node message
            if( synthArray[nodeID] == NULL )
            {
                if( gMasterDebug )
                    <<< "MASTER ERROR: trigger message for non-existent node ","" >>>;    // DEBUG
                int seq[];
                twtNodeData a @=> synthArray[ nodeID ];
                Std.rand2( gMinWavNum, gMaxWavNum ) => int tempWavNum;            
                //synthArray[ nodeID ].init( nodeID, tempWavNum, gModeNum, 6., 1., gDecTimes[gTimeNum], gAttTimes[gTimeNum], gStepTimes[gTimeNum]  );
                synthArray[ nodeID ].init( nodeID, tempWavNum, gModeNum, gFltRatios[tempWavNum], 1., gDecTimes[tempWavNum], gAttTimes[gTimeNum], gStepTimes[gTimeNum], Std.rand2f(-.3, .3)  );
               "missing message!" => synthArray[ nodeID ].msgStr;
                
                gFirstHopTimes[ gTimeNum ] => synthArray[ nodeID ].mFirstHopTime;
                gHopTimes[ gTimeNum ] => synthArray[ nodeID ].mHopTime;
  
                gNextTreeNum => synthArray[ nodeID ].treeNum;
                gNextClient => synthArray[ nodeID ].clientNum;
                0 => synthArray[ nodeID ].isLocal;
                 
                Std.rand2( gMinSeqNum, gMaxSeqNum ) => int tempSeqNum;             
                seqArray[ tempSeqNum ] @=> seq;
                synthArray[ nodeID ].setNoteSeq( seq );
                sendNewNode( nodeID );  
                
                // TODO: add treeNum and Client Num stuff here!       
            }             
     
            spork ~ sendTrigger( nodeID, echoID, delayMsec, hopLevel); 
        }
    }
}

// send trigger messages -------------------------------------------------
fun void sendTrigger( string nodeID, int echoID, float delayMsec, int hopLevel )
{
    time triggerTime;
    
    // if this is the first trigger for a given echoID set the current time
    if ( hopLevel == 0 )
    {
        now => echoStartTime[ echoID ];
        now => triggerTime;
    }
    
    // if this is a subsequent hop set the time based on the delta
    else
    {
        if( now - echoStartTime[echoID] > 20::second )   // why did I put this here???  -LD 7/26/10, I guess in case the trigger arrived before the first trigger in the tree.
        {
            now => echoStartTime[echoID];
        }        
        delayMsec * 1::ms + echoStartTime[echoID] => triggerTime;
    }
    
    // if too many hops down, don't send. duplicated code from twtNodeSynth2 trigger()
    0. => float dbdown;
    if( hopLevel > 0) 5 + 1.5*(hopLevel-1) => dbdown;    // first hop is -4db, themn -2db more for each subsequent hop     
    if( dbdown > 70 ) return;                            // if we are already super quiet, no need to play or send messages
    
    triggerTime => now;    // wait to send message

    if( gMasterDebug )
        <<< "MASTER: sending trigger for node ", nodeID, "echoID", echoID, "hop" ,hopLevel >>>;    
    
    // send trigger message to processing:
    osc_proc_out.startMsg( "/twt/triggerNode", "i s f i");
    echoID => osc_proc_out.addInt;                 // echoID
    nodeID => osc_proc_out.addString;              // nodeID
    0.0 => osc_proc_out.addFloat;                  // delay in ms
    hopLevel => osc_proc_out.addInt;               // hopLevel

    // send trigger message to chuck client:
    osc_out.setHost( clients[ synthArray[nodeID].clientNum ], out_port );
    osc_out.startMsg( "/twt/triggerLocalNode", "i s f i");
    echoID => osc_out.addInt;                     // echoID
    nodeID => osc_out.addString;                  // nodeID
    0.0 => osc_out.addFloat;                      // delay in ms
    hopLevel => osc_out.addInt;                   // hopLevel
}

// inc/decrement the range of possible wavs for the next new tree
fun void incdecWavs( int incdec, int cyc )
{
    //cyc = 1 if instead of pegging at boundaries we go back to beginning
    if( incdec) {
        1 +=> gWavNum;
        gWavNum-1 => gMinWavNum;
        gWavNum+1 => gMaxWavNum; 
    }
    else {
        1 -=> gWavNum; 
        gWavNum-1 => gMinWavNum;   // set min
        gWavNum+1 => gMaxWavNum;   // set max
    }
    if( cyc )
    {
        if( gMaxWavNum >= gNumWavFiles ){
            0 => gWavNum; 
            0 => gMinWavNum;
            1 => gMaxWavNum; 
        }
        if( gMinWavNum < 0 ){
            gNumWavFiles-1 => gMaxWavNum;
            gNumWavFiles-1 => gMinWavNum;
            gNumWavFiles-1 => gWavNum;
        }
    }
    else {
        if( gWavNum < -1)
            -1 => gWavNum;
        if(gMinWavNum < 0) 
            0 => gMinWavNum;                              // set min
        if(gMaxWavNum < 0) 
            0 => gMaxWavNum;                              // set min
        if( gWavNum > gNumWavFiles ) 
            gNumWavFiles => gWavNum;
        if(gMaxWavNum >  gNumWavFiles-1) 
            gNumWavFiles-1 => gMaxWavNum;   // set max
        if(gMinWavNum >  gNumWavFiles-1) 
            gNumWavFiles-1 => gMinWavNum;   // set max
    }

    <<< "//////////////////////// wavs ", gMinWavNum, " to ", gMaxWavNum >>>;
    //<<< "//////////////////////// wavs ", gMinWavNum, " to ", gMaxWavNum, gWavNames[gMinWavNum], gWavNames[gMinWavNum+1], gWavNames[gMaxWavNum]  >>>;
}

// inc/decrement the range of possible melody sequences for the next new tree
fun void incdecSeqs( int incdec, int cyc )
{
    //cyc = 1 if instead of pegging at boundaries we go back to beginning
    if( incdec) {
        1 +=> gSeqNum;
        gSeqNum-1 => gMinSeqNum;
        gSeqNum+2 => gMaxSeqNum; 
    }
    else {
        1 -=> gSeqNum; 
        gSeqNum-1 => gMinSeqNum;   // set min
        gSeqNum+2 => gMaxSeqNum;   // set max
    }
    if( cyc )
    {
        if( gMaxSeqNum >= gNumSeqs ){
            0 => gSeqNum; 
            0 => gMinSeqNum;
            1 => gMaxSeqNum; 
        }
        if( gMinSeqNum < 0 ){
            gNumSeqs-1 => gMaxSeqNum;
            gNumSeqs-1 => gMinSeqNum;
            gNumSeqs-1 => gSeqNum;
        }
    }
    else {
        if( gSeqNum < -1)
            -1 => gSeqNum;
        if(gMinSeqNum < 0) 
            0 => gMinSeqNum;                              // set min
        if(gMaxSeqNum < 0) 
            0 => gMaxSeqNum;                              // set min
        if( gSeqNum > gNumSeqs ) 
            gNumSeqs => gSeqNum;
        if(gMaxSeqNum >  gNumSeqs-1) 
            gNumSeqs-1 => gMaxSeqNum;   // set max
        if(gMinSeqNum >  gNumSeqs-1) 
            gNumSeqs-1 => gMinSeqNum;   // set max
    }
    
    <<< "//////////////////////// melody ", gMinSeqNum, " to ", gMaxSeqNum >>>;
}


// keyboard listener (for user control) -----------------------------------------------
fun void keyboard()
{
    Hid hiKbd;
    HidMsg msgKbd;
    
    // which keyboard
    0 => int device;
    
    // open keyboard
    if( !hiKbd.openKeyboard( device ) ) me.exit();
    <<< "keyboard '", hiKbd.name(), "' ready" >>>;

    while (true)
    {
        // wait on event
        hiKbd => now;
        while( hiKbd.recv( msgKbd ) )
        {
            // check for action type
            if( msgKbd.isButtonDown() )
            {
                // keys '1' and '2': melody
                if( msgKbd.which == 31) {
                    incdecSeqs( 1, 0);
                }
                else if( msgKbd.which == 30) {
                    incdecSeqs( 0, 0);
                }
                
                // keys '3' and '4': wav
                else if( msgKbd.which == 33) {
                    incdecWavs( 1, 0 );
                }
                else if( msgKbd.which == 32) {
                    incdecWavs( 0, 0 );                    
                }
                                            
                // keys '5' and '6': timing
                else if( msgKbd.which == 35) {
                    1 +=> gTimeNum;
                    if( gTimeNum > gNumTimes-1 ) gNumTimes-1 => gTimeNum;
                    <<< "//////////////////////// timing ", gTimeNum>>>;
                }
                else if( msgKbd.which == 34) {
                    1 -=> gTimeNum;
                    if( gTimeNum < 0 ) 0 => gTimeNum;
                    <<< "//////////////////////// timing ", gTimeNum>>>;
                }
                    
                // keys '7' and '8': mode
                else if( msgKbd.which == 37) {
                    1 +=> gModeNum;
                    if( gModeNum > gNumModes-1 ) gNumModes-1 => gModeNum;                       
                    <<< "//////////////////////// mode ", gModeNum>>>;
                }
                else if( msgKbd.which == 36) {
                    1 -=> gModeNum;
                    if( gModeNum < 0 ) 0 => gModeNum;
                    <<< "//////////////////////// mode ", gModeNum>>>;
                }
                
                // keys '9' and '0': dry level
                else if( msgKbd.which == 38) {
                    changeDry( 0 );
                }
                else if( msgKbd.which == 39) {
                    changeDry( 1 );
                }
                
                // changing LOCAL dequeue times: ghjk
                // dec min time
                else if( msgKbd.which == 10) {       // 'g'
                    incdecLocQueueTimes( 0, 0 );
                }                 
                // inc min time
                else if( msgKbd.which == 11) {     // 'h'
                    incdecLocQueueTimes( 1, 0 );
                }
                // dec max time
                else if( msgKbd.which == 13) {      // 'j'
                    incdecLocQueueTimes( 0, 1 );
                }
                // inc max time
                else if( msgKbd.which == 14) {      // 'k'
                    incdecLocQueueTimes( 1, 1 );
                }
                 
                // changing GLOBAL dequeue times: asdf
                // dec min time
               else if( msgKbd.which == 4) {       // 'a'
                   incdecQueueTimes( 0, 0 );
               }
                // inc min time
               else if( msgKbd.which == 22) {     // 's'
                   incdecQueueTimes( 1, 0 );
               }

                // dec max time
                else if( msgKbd.which == 7) {      // 'd'
                    incdecQueueTimes( 0, 1 );
                }
                // inc max time
                else if( msgKbd.which == 9) {      // 'f'
                    incdecQueueTimes( 1, 1 );
                }                
                
                // python new tree threshold
                else if( msgKbd.which == 54) {      // ','
                    sendTreeThresh(0);
                }
                else if( msgKbd.which == 55) {      // '.'
                    sendTreeThresh(1);
                }
                
 /*
 else if( msgKbd.which == 54) {      // ','
     0 => gPlayLocal;
     setSynthStatics();
     <<< "//////////////////////// playLocal ", gPlayLocal>>>;
 }
 else if( msgKbd.which == 55) {      // '.'
     1 => gPlayLocal;
     setSynthStatics();
     <<< "//////////////////////// playLocal ", gPlayLocal>>>;
 }
 */
                // adding removing search terms: zx-not c-vbnm
                else if( msgKbd.which == 29) {     // 'z'
                    addRemove( 0 );
                }
                else if( msgKbd.which == 27) {     // 'x'
                    addRemove( 1 );
                }
                else if( msgKbd.which == 6) {     // 'c'  - not used due to needing ctrl-C
                    //addRemove( 2 );
                }
                else if( msgKbd.which == 25) {     // 'v'
                    addRemove( 2 );
                }
                else if( msgKbd.which == 5) {     // 'b'
                    addRemove( 3 );
                }
                else if( msgKbd.which == 17) {     // 'n'
                    addRemove( 4 );
                }
                else if( msgKbd.which == 16) {     // 'm'
                    addRemove( 5 );
                }

                else {
                    //<<< "unknown key ", msgKbd.which >>>;
                }
            }
        }
    }
}

// process for reading midi-control
fun void midiCtl()
{
    while( true )
    {
        // wait on the event 'midiIn'
        midiIn => now;       
        // get the message(s)
        while( midiIn.recv(msg) )
        {
            // THE SLIDERS ------------------------------------------------
            if( msg.data1 == 176 && msg.data2 == 13 )   // slider 9
            {
                //<<< "slider 9 = ", msg.data3 >>>;
                
                // change threshold
                msg.data3 / 127. => gTreeThresh;
                osc_pyth_out.startMsg("/twt/treeThresh", "f");
                gTreeThresh => osc_pyth_out.addFloat;
                //<<< "//////////////////////// new tree thresh ", gTreeThresh >>>;
            }
            else if( msg.data1 == 176 && msg.data2 == 12 ) // slider 8
            {
                // change global density
                1. - (msg.data3 / 127.) => float tempDens;
                
                0.5 + tempDens*10. => gMaxQueueTime;
                0.3 + tempDens*4. => gMinQueueTime;
                sendQueueTimes(1);
            }
            else if( msg.data1 == 176 && msg.data2 == 37 ) // button
            {
                if( msg.data3 == 127)
                    addRemove( 0 );
            }
            else if( msg.data1 == 176 && msg.data2 == 38 ) // button
            {
                if( msg.data3 == 127)
                    addRemove( 1 );
            }
            else if( msg.data1 == 176 && msg.data2 == 39 ) // button
            {
                if( msg.data3 == 127)
                    addRemove( 2 );
            }
            else if( msg.data1 == 176 && msg.data2 == 40 ) // button
            {
                if( msg.data3 == 127)
                    addRemove( 3 );
            }
            else if( msg.data1 == 176 && msg.data2 == 41 ) // button
            {
                if( msg.data3 == 127)
                    addRemove( 4 );
            }
            else
            {
                //<<< "unassigned midi message: ", msg.data1, msg.data2, msg.data3 >>>;
            }
            
        }
    }
}


// send the start message to python
fun void sendTreeThresh( int upDown )
{
    if( upDown ) {
        0.05 +=> gTreeThresh;
        if( gTreeThresh > 1.0 ) 1.0 => gTreeThresh;
    }
    else {
        0.05 -=> gTreeThresh;
        if( gTreeThresh < 0. ) 0. => gTreeThresh;
    }
        
    osc_pyth_out.startMsg("/twt/treeThresh", "f");
    gTreeThresh => osc_pyth_out.addFloat;
    <<< "//////////////////////// new tree thresh ", gTreeThresh >>>;
}

// change master dry level and send messages
fun void changeDry( int upDown )
{
    if( upDown ) {
        gDryLvl * 1.1 => gDryLvl;
        if( gDryLvl > 1.0 ) 1.0 => gDryLvl;
    }
    else {
        gDryLvl * 0.9 => gDryLvl;
    }
    
    // send message to chuck clients
    for(0 => int i; i < gNumClients; i++) {
        osc_out.setHost( clients[i], out_port );
        osc_out.startMsg( "/twt/setDryLvl, f");
        gDryLvl => osc_out.addFloat;  
    }
    
    <<< "//////////////////////// dry lvl ", gDryLvl>>>;
}

// send the latest threshold to python
fun void sendThreshold()
{
    osc_pyth_out.startMsg("/twt/treeThresh", "f");
    gTreeThresh => osc_pyth_out.addFloat;
}
        
// send min and max dequeue times to python
fun void sendQueueTimes( int glob)
{
    // /twt/dequeueTime fmin fmax global
    // 0 is local 1 is global
    if( glob ) {
        osc_pyth_out.startMsg("/twt/dequeueTime", "f f i");
        gMinQueueTime => osc_pyth_out.addFloat;
        gMaxQueueTime => osc_pyth_out.addFloat;
        1 => osc_pyth_out.addInt;
        //<<< "//////////////////////// GLOBAL que times ", gMinQueueTime, gMaxQueueTime >>>;
    }
    else {
        osc_pyth_out.startMsg("/twt/dequeueTime", "f f i");
        gMinLocQueueTime => osc_pyth_out.addFloat;
        gMaxLocQueueTime => osc_pyth_out.addFloat;
        0 => osc_pyth_out.addInt;
        //<<< "//////////////////////// LOCAL que times ", gMinLocQueueTime, gMaxLocQueueTime >>>;        
    }
}

// increment or decrement the max or min local dequeue times
fun void incdecLocQueueTimes( int incdec, int maxmin )
{
    // incdec = increment, !incdec = decrement
    // maxmin = max, !maxmin = min
    
    // factors to multiply when increasing or decreasing
    1.1 => float incfact;
    1./incfact => float decfact;
    
    // dec min time
    if( !incdec && !maxmin ) 
    {
        //0.1 -=> gMinLocQueueTime;
        decfact *=> gMinLocQueueTime;
        if( gMinLocQueueTime < 0.1 )
            0.1 => gMinLocQueueTime;
        sendQueueTimes(0);
    }                 
    // inc min time
    else if( incdec && !maxmin ) 
    {     
        //0.1 +=> gMinLocQueueTime;
        incfact *=> gMinLocQueueTime;
        if( gMinLocQueueTime > gMaxLocQueueTime )
            gMaxLocQueueTime => gMinLocQueueTime;
        sendQueueTimes(0);
    }
    // dec max time
    else if( !incdec && maxmin ) 
    {
        // 0.1 -=> gMaxLocQueueTime;
        decfact *=> gMaxLocQueueTime;
        if( gMaxLocQueueTime < 0.3 )
            0.3 => gMaxLocQueueTime;
        if( gMaxLocQueueTime < gMinLocQueueTime )
            gMinLocQueueTime + 0.1 => gMaxLocQueueTime;
        sendQueueTimes(0);
    }
    // inc max time
    else if( incdec && maxmin ) 
    {     
        // 0.1 +=> gMaxLocQueueTime;
        incfact *=> gMaxLocQueueTime;
        sendQueueTimes(0);
    }   
}

// increment or decrement the max or min global dequeue times
fun void incdecQueueTimes( int incdec, int maxmin )
{
    // incdec = increment, !incdec = decrement
    // maxmin = max, !maxmin = min
    
    // factors to multiply when increasing or decreasing
    1.2 => float incfact;
    1./incfact => float decfact;

    
    // dec min time
    if( !incdec && !maxmin ) 
    {
        //0.1 -=> gMinQueueTime;
        decfact *=> gMinQueueTime;
        if( gMinQueueTime < 0.1 )
            0.1 => gMinQueueTime;
        sendQueueTimes(1);
    }                 
    // inc min time
    else if( incdec && !maxmin ) 
    {     
        //0.1 +=> gMinQueueTime;
        incfact *=> gMinQueueTime;
        if( gMinQueueTime > gMaxQueueTime )
            gMaxQueueTime => gMinQueueTime;
        sendQueueTimes(1);
    }
    // dec max time
    else if( !incdec && maxmin ) 
    {
        //0.1 -=> gMaxQueueTime;
        decfact *=> gMaxQueueTime;
        if( gMaxQueueTime < 0.2 )
            0.2 => gMaxQueueTime;
        if( gMaxQueueTime < gMinQueueTime )
            gMinQueueTime + 0.1 => gMaxQueueTime;
        sendQueueTimes(1);
    }
    // inc max time
    else if( incdec && maxmin ) 
    {     
        //0.1 +=> gMaxQueueTime;
        incfact *=> gMaxQueueTime;
        sendQueueTimes(1);
    }   
}




// send add remove terms to search terms
fun void addRemove( int termIdx )
{
    if( termIdx >= gNumTerms) return;
    
    if( gTermsIn[ termIdx ] ) 0 => gTermsIn[ termIdx ];
    else 1 => gTermsIn[ termIdx ];
    gTermsIn[ termIdx ] => int inOut;
    
    if( inOut ) {        
        // send to python
        osc_pyth_out.startMsg("/twt/addTerm", "s");
        gTerms[ termIdx ] => osc_pyth_out.addString;
        
        // send to processing
        osc_proc_out.startMsg("/twt/addTerm", "s");
        gTerms[ termIdx ] => osc_proc_out.addString;

        <<< "++++++++++++++++++++++++ adding term:", gTerms[ termIdx ], "+++" >>>;
    }
    else {
        // send to python
        osc_pyth_out.startMsg("/twt/removeTerm", "s");
        gTerms[ termIdx ] => osc_pyth_out.addString;
        
        // send to processing
        osc_proc_out.startMsg("/twt/removeTerm", "s");
        gTerms[ termIdx ] => osc_proc_out.addString;

        <<< "------------------------ removing term:", gTerms[ termIdx ], "---" >>>; 
    }
    
}

// functions for sequence generation ===================================================

// create the sequence for a newNode from its neigbor's sequence
fun void setSeqForNewNode( string nodeID, string neighborID)
{
    // create the noteSeq array for the new node (presumably using the neighbor's noteSeq
    int dummy[twtNodeData.numSeqSteps];
    
    // first get the original
    twtNodeData.numSeqSteps => int numSS;
    for( 0 => int i; i < numSS; i++ )
    {
        synthArray[neighborID].getNoteSeqAtIndex(i) => dummy[i];
    }
    
    5 => int numMutations;
    Std.rand2( -3, 3) => int transpose;      // pick a transposition interval
        
    for( 0 => int n; n < numMutations; n++ )
    {
        Std.rand2(0,1) => int mut;
        
        // transpose a note
        if (mut == 0) 
        {
            Std.rand2(0,numSS-1) => int ind3;
            if(  dummy[ ind3 ] != nonote )
                dummy[ ind3 ] + transpose => dummy[ ind3 ];
        }
        
        // flip two notes
        if (mut == 1)
        {
            Std.rand2(0,numSS-1) => int ind1;
            Std.rand2(0,numSS-1) => int ind2;                        
            dummy[ind1] => int temp1;
            dummy[ind2] => dummy[ind1];
            temp1 => dummy[ind1];
        }
    }
    
    // keep each seq within a certain range:
    
    // find the max and min in the seq;
    1000 => int min; -1000 => int max;
    for( 0 => int i; i < numSS; i++ )
    {
        if( (dummy[i] < min) && (dummy[i] != nonote) ) {
            dummy[i] => min;
        }
        if( (dummy[i] > max) && (dummy[i] != nonote)) {
            dummy[i] => max;
        }
    }
    if ( (max - min) > 10 )             // if the spread is too great, compress!
    {         
        if( gMasterDebug )
            <<< "compressing sequence! ", max, min >>>;   // DEBUG
        for( 0 => int i; i < numSS; i++ ) 
        {
            if( dummy[i] != nonote) 
            {
                Math.floor( dummy[i]/2 )$int => dummy[i];
            }
        }
    }
    // if transposed too high or too low, transpose all
    1000 => min; -1000 => max;
    for( 0 => int i; i < numSS; i++ )
    {
        if( (dummy[i] < min) && (dummy[i] != nonote) ) 
        {
            dummy[i] => min;
        }
        if( (dummy[i] > max) && (dummy[i] != nonote)) 
        {
            dummy[i] => max;
        }
    }
    if( (max > 16) || (min < -16) ) 
    {
        0.5*(max + min) => float mean;
        if( gMasterDebug )
            <<< "transposing sequence ", max, min, mean >>>;   // DEBUG
        Math.floor( .5*mean )$int => int xpose;
        for( 0 => int i; i < numSS; i++ )
        {
            if( dummy[i] != nonote) 
            {
                dummy[i] - xpose => dummy[i];
            }
        }
    }
    
    // make sure first note is an "on note"
    if( dummy[0] == nonote )
    {
        if( gMasterDebug )
            <<< "first note null!","">>>; // TODO: add code here
    }
    
    // and set the array
    synthArray[ nodeID ].setNoteSeq( dummy );   
}







