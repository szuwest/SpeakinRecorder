# 手机局域网内（包括热点）组网通讯实现

最近在做一个应用，需要多个手机一起组网，一个充当主机，其他多个手机充当从机。主机跟每个从机之间可以相互通信，发送消息和文件。这不就是个CS（client-server）模式吗，只不过server不是在云端，只是在同一个局域网的手机上罢了。

这里面有两个关键的地方，一个是如何发现同一个局域网内的手机客户端，包括自建的热点，一个是知道各个手机的Ip地址后，用什么方式来建立通信。这里说一下热点，手机开启热点之后，别的手机连上这个特点，其实也是一个小型局域网，只不过这个局域网稍微有点不一样（Ip地址），其他的都一样。

## 局域网发现
局域网发现主要难点在于如何得到对方Ip地址。我们的做法是发送UDP包。UDP协议是无面向连接的，也就是不需要像TCP协议那样提前建立连接。所以我们向局域网内某一个特定的端口广播UDP包，接收到这个包的人，发送回包，那么我们就知道彼此的存在和地址。

那么关键地方是

* 有人一直在监听一个端口X，接收UDP包
* 有人在一直往这个端口X发送UDP包

监听端的人收到了UDP包后，就知道了发送者的Ip地址。但这时发送者是不知道接收者的，因为这是UDP包，无连接的状态的。那怎么做才让发送者也知道了。其实只要发过来再做一次就行。发送者同时也是监听者，这就行了。不过发送者A监听的是另一个端口Y，接收者B接收到包后，发送一个Y端口的包给A就行了。

总结起来：

* 主机监听端口X，一直发送Y端口的广播UDP包
* 从机监听端口Y，接收到UDP包后，往X端口发送UDP包。

这样就能双方知道对方的Ip地址了。发送的数据包也可以很讲究，例如发送json数据，可以自己定义一些字段，当接收者收到之后，解析数据，如果不符合规则的数据包直接丢弃掉。这就可以支撑一些业务逻辑了。

### 广播地址
广播地址是什么呢，一般都是用255.255.255.255，也有不用广播用组播地址例如192.168.43.255.这个组播地址就是热点的时候采用的地址，因为开启热点之后，那个手机的IP地址是固定的，是192.168.43.1其他端的手机都是这个地址后面的192.168.43.X。如果广播发送不了或者被禁掉了？一般来说还有一种方法，就是子网掩码里面的所有Ip地址遍历发一遍，这也是办法之一。

## 一对多的通信

当知道对方的Ip地址后，一切都好办了。端对端的通信有挺多方法，一对多的通信也不少。如果要同时考虑在Android和iOS都好实现的话，其实可选的不是很多。

最保守的方法就是直接采用TCP协议建立sock来通信。在iOS端和Android端都有很好的socket库，不用担心能不能实现和兼容性问题。这个方案挺好但是缺点也明显，因为sock通信只定义了最基础的，消息格式要完全自己定制和实现，还多心跳之类的，这里的工作量还不少。也许还有少的框架实现了这些，但是要同时在iOS端和安卓端都有实现，我还真不知道有哪些。而且我的情景里最重要的是有一个主机在里面，所有的从机都跟主机通信，所以必须说要有一个server。

我后来采用的的WebSocket来实现。WebSocket在Android上有很多库，不过大多数都是client端的,包括了server端的有AndroidAsync,Java-Websocket。我采用的是AndroidAysnc。而iOS端可选择的就更少了。我在github上找了很多库，都是只支持client的，有支持server的都是很久很老的项目，找到一个采用swift写的叫Telegraph库，试用了起来，这个库实现得不是很好，有挺多问题，不尽如意。最终现在iOS端只有采用了Facebook的SocketRocket来作为client端，server端暂时没有好的实现。

采用WebSocket来实现双向通信有不少好处，例如它直接支持发送字符串消息，二进制数据（文件），还有连接上和断开都有相应的事件，还有ping-pong这种心跳机制，我觉得挺好的。iOS端的WebSocket server暂时没有找到可靠的第三方实现，比较遗憾。

我自己做了demo工程，上传到github。

* [Android局域网发现和建立一对多通信](https://github.com/szuwest/Recorder)
* [iOS局域网发现和建立一对多通信](https://github.com/szuwest/SpeakinRecorder)
