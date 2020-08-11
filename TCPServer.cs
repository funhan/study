using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

public class TCPServer : MonoBehaviour
{
    private TcpListener tcpListener;
    private Thread tcpListenerThread;
    private TcpClient client;
    
    private string ipAddress = "127.0.0.1";
    private const int port = 8888;

    // Start is called before the first frame update
    void Start()
    {
        tcpListenerThread = new Thread(new ThreadStart(Listen));
        tcpListenerThread.IsBackground = true;
        tcpListenerThread.Start();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void Listen()
    {
        IPAddress ipAddr = IPAddress.Parse(ipAddress);
        IPEndPoint ipEndPoint = new IPEndPoint(ipAddr, port);

        tcpListener = new TcpListener(ipEndPoint);
        tcpListener.Start();
        Debug.Log("Server is listening");

        byte[] bytes = new byte[1];

        const int headerSize = 4;
        int offset = 0;
        int lengthToRead = 0;
        int size;
        string body;

        int check = 0;
        byte[] buf = new byte[4];
        

        while (true)
        {
            using (client = tcpListener.AcceptTcpClient())
            {
                using (NetworkStream stream = client.GetStream())
                {
                    int length = 0;
                    
                    switch (check) {
                        case 0:
                            if (offset >= headerSize)
                            {
                                Debug.Log("asdasd");
                                check = 1;
                                byte[] data = new byte[headerSize];
                                Array.Copy(bytes, 0, data, 0, headerSize);
                                int ts = BitConverter.ToInt32(buf, 0);
                                //string msg = Encoding.UTF8.GetString(data);
                                Debug.Log("client msg : " + ts + " " + headerSize);
                            }
                            while ((length = stream.Read(bytes, 0, bytes.Length)) != 0)
                            {
                                if (offset + length <= headerSize)
                                {
                                    Array.Copy(bytes, 0, buf, offset, length);
                                    offset += length;
                                    string msg = Encoding.UTF8.GetString(bytes);
                                    Debug.Log("client test : " + msg.ToString());
                                    Debug.Log(offset);
                                    //byte[] data = new byte[length];
                                    //Array.Copy(bytes, 0, data, 0, length);
                                }                                

                                //string msg = Encoding.UTF8.GetString(data);
                                //Debug.Log("client msg : " + msg + " " + length);
                            }
                            break;
                        case 1:

                            break;
                    }
                }
            }
        }
    }
}
