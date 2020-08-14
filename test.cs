using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.IO;
using System;
using System.Text;

public class Client : MonoBehaviour
{
    public static Client instance = null;
    public static int dataBufferSize = 1024;
    
    public string ip = "127.0.0.1";
    public int port = 8888;
    public TCP tcp;

    private delegate void PacketHandler(Packet packet);
    private static Dictionary<int, PacketHandler> packetHandlers;
    private void Awake()
    {
        if (instance == null)
        {
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(this);
        }
    }

    private void Start()
    {
        Debug.Log("client start..");
        tcp = new TCP();
        ConnectToServer();
    }

    private void ConnectToServer()
    {
        InitializePacketHandler();
        tcp.Connect();
    }

    private void InitializePacketHandler()
    {
        packetHandlers = new Dictionary<int, PacketHandler>()
        {
            {0,  ClientHandle.UserAuthentication }
        };
        
    }

    public class TCP
    {
        public TcpClient socket;

        private NetworkStream stream;
        private Packet receivedData;
        private byte[] receiveBuffer;

        public void Connect()
        {
            socket = new TcpClient();
            socket.ReceiveBufferSize = dataBufferSize;
            socket.SendBufferSize = dataBufferSize;  
            
            receiveBuffer = new byte[dataBufferSize];
            socket.BeginConnect(instance.ip, instance.port, ConnectCallback, null);

        }

        private void ConnectCallback(IAsyncResult result)
        {
            socket.EndConnect(result);

            if (!socket.Connected)
            {
                Debug.Log("disconnect..");
                return;
            }

            stream = socket.GetStream();
            receivedData = new Packet();
            stream.BeginRead(receiveBuffer, 0, dataBufferSize, ReceiveCallback, null);
        }

        private void ReceiveCallback(IAsyncResult result)
        {
            int byteLength = stream.EndRead(result);

            if (byteLength == 0) // disconnect
            {
                return;
            }

            byte[] data = new byte[byteLength];
            Array.Copy(receiveBuffer, data, byteLength);


            // 만약에 받은 data에서 안읽은 바이트가 6바이트 이상이면 이건 헤더다.!
            // 아니면 계속해서 받아야 한다. 그럴때 받은 데이터를 어디다 저장해야한다.
            // receivedData.buffer에 저장해놓고 사용

            receivedData.Reset(HandleReceiveData(data));
            stream.BeginRead(receiveBuffer, 0, dataBufferSize, ReceiveCallback, null);
        }

        private bool HandleReceiveData(byte[] data)
        {
            receivedData.SetBytes(data);

            int packetLength = 0;
            short type = 0;
            byte[] packetHeader = new byte[0];

            if (receivedData.UnreadBufferLength() >= Packet.headerSize)
            {
                packetHeader = receivedData.ReadBytes(Packet.headerSize);
                if (packetHeader.Length == 0)
                {
                    return true;
                }
                Array.Reverse(packetHeader);
                packetLength = BitConverter.ToInt32(packetHeader, 2);
                type = BitConverter.ToInt16(packetHeader, 0);
                Debug.Log("length : " + packetLength + ", type : " + type);
                //packetLength = receivedData.ReadInt();
                //type = receivedData.ReadShort();
            }

            while (packetLength > 0 && packetLength <= receivedData.UnreadBufferLength())
            {
                byte[] packetBody = receivedData.ReadBytes(packetLength);

                ThreadManager.ExecuteMainThread(() =>
                {
                    using (Packet packet = new Packet(packetBody))
                    {
                        packetHandlers[(int)type](packet);
                    }
                });
                
                Data json = JsonUtility.FromJson<Data>(Encoding.UTF8.GetString(packetBody));
                Debug.Log("test : " + json.value);
                packetLength = 0;
                if (receivedData.UnreadBufferLength() >= Packet.headerSize)
                {
                    packetHeader = receivedData.ReadBytes(Packet.headerSize);
                    if (packetHeader.Length == 0)
                    {
                        return true;
                    }

                    Array.Reverse(packetHeader);
                    packetLength = BitConverter.ToInt32(packetHeader, 2);
                    type = BitConverter.ToInt16(packetHeader, 0);

                    //packetLength = receivedData.ReadInt();
                    //type = receivedData.ReadShort();
                }
            }

            if (packetLength == 0)
            {
                return true;
            }

            return false;
        }

        public void SendData(Packet packet)
        {
            if(socket != null)
            {
                byte[] data = packet.ReadBytes(packet.UnreadBufferLength());
                stream.BeginWrite(data, 0, data.Length, null, null);
            }
        }
    }
}

///////////////////////////////////////
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Text;
using System;

public class Data
{
    public string value;
}

public class Packet : IDisposable
{
    private List<byte> buffer;
    private byte[] readableBuffer;
    private int readPos;

    public static int headerSize = 6;

    public Packet()
    {
        buffer = new List<byte>();
        readPos = 0;
    }
    public Packet(byte[] data)
    {
        buffer = new List<byte>();
        readPos = 0;
        SetBytes(data);
    }

    public void SetBytes(byte[] data)
    {
        buffer.AddRange(data);
        readableBuffer = buffer.ToArray();
    }

    public void Reset(bool isReset)
    {
        if (isReset)
        {
            buffer.Clear();
            readableBuffer = null;
            readPos = 0;
        }
        else
        {
            readPos -= headerSize;
        }
    }

    public int UnreadBufferLength()
    {
        return buffer.Count - readPos;
    }

    public byte[] ReadBytes(int length)
    {
        if (buffer.Count > readPos)
        {
            byte[] value = buffer.GetRange(readPos, length).ToArray();
            readPos += length;
            return value;
        }
        else
        {
            return new byte[0];
        }
    }

    public int ReadInt()
    {
        if (buffer.Count > readPos)
        {
            int value = BitConverter.ToInt32(readableBuffer, readPos);
            readPos += 4;
            ConvertEndian(ref value);
            return value;
        }
        else
        {
            return 0;
        }
    }
    public short ReadShort()
    {
        if (buffer.Count > readPos)
        {
            short value = BitConverter.ToInt16(readableBuffer, readPos);
            readPos += 2;
            ConvertEndian(ref value);
            return value;
        }
        else
        {
            return 0;
        }
    }

    public void Write(byte[] data)
    {
        buffer.AddRange(data);
    }



    
    public static void ConvertEndian(ref int value)
    {
        byte[] data = BitConverter.GetBytes(value);
        Array.Reverse(data);
        value = BitConverter.ToInt32(data, 0);
    }
    public static void ConvertEndian(ref short value)
    {
        byte[] data = BitConverter.GetBytes(value);
        Array.Reverse(data);
        value = BitConverter.ToInt16(data, 0);
    }

    // IDisposable 구현 패턴
    // 한시적으로 사용해야 할 필요가 있는 자원들을 묶어서 관리할 때에는 
    // IDisposable 패턴을 적극적으로 활용하는 것이 유용
    private bool disposed = false;

    protected virtual void Dispose(bool disposing)
    {
        if (!disposed)
        {
            if (disposing)
            {
                buffer = null;
                readableBuffer = null;
                readPos = 0;
            }
            disposed = true;
        }
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }
}

///////////////////////////////////////
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

public class ClientHandle : MonoBehaviour
{
    public static void UserAuthentication(Packet packet)
    {
        Debug.Log("UserAuthentication ...");
        byte[] msg = packet.ReadBytes(packet.UnreadBufferLength());
        Data json = JsonUtility.FromJson<Data>(Encoding.UTF8.GetString(msg));
        Debug.Log(json.value);
        ClientSend.UserAuthenticationReceived();
    }

}

///////////////////////////////////////
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ThreadManager : MonoBehaviour
{
    private static List<Action> mainThread = new List<Action>();
    private static List<Action> copyMainThread = new List<Action>();
    private static bool actionToMainThread = false;

    // Update is called once per frame
    void Update()
    {
        UpdateMainThread();
    }

    public static void ExecuteMainThread(Action action)
    {
        if(action == null)
        {
            return;
        }

        lock(mainThread)
        {
            mainThread.Add(action);
            actionToMainThread = true;
        }
    }

    public static void UpdateMainThread()
    {
        if(actionToMainThread)
        {
            copyMainThread.Clear();

            lock(mainThread)
            {
                copyMainThread.AddRange(mainThread);
                mainThread.Clear();
                actionToMainThread = false;
            }

            for(int i=0;i< copyMainThread.Count;++i)
            {
                copyMainThread[i]();
            }
        }

    }
}

///////////////////////////////////////
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

public class ClientSend : MonoBehaviour
{
    private static void SendToServer(Packet packet)
    {
        Client.instance.tcp.SendData(packet);
    }

    public static void UserAuthenticationReceived()
    {
        Packet packet = new Packet();

        Data data = new Data();
        data.value = "world!!";

        byte[] byteJson = Encoding.UTF8.GetBytes(JsonUtility.ToJson(data));

        byte[] byteSize = BitConverter.GetBytes(byteJson.Length);
        if (BitConverter.IsLittleEndian)
            Array.Reverse(byteSize);
        byte[] byteType = BitConverter.GetBytes((short)0);
        if (BitConverter.IsLittleEndian)
            Array.Reverse(byteType);


        packet.Write(byteSize);
        packet.Write(byteType);
        packet.Write(byteJson);

        SendToServer(packet);
    }
}
///////////////////////////////////////
