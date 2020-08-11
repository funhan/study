using System;
using System.Collections;
using System.Collections.Generic;
using System.Net.Sockets;
using System.Net;
using System.Text;
using System.Threading;
using UnityEngine;

public class TCPClient : MonoBehaviour
{
    private TcpClient tcpClient;
    private Thread tcpClientThread;

    private string ipAddress = "127.0.0.1";
    private const int port = 8888;

    byte[] sizeBuffer;
    byte[] typeBuffer;
    byte[] bodyBuffer;

    // Start is called before the first frame update
    void Start()
    {
        tcpClientThread = new Thread(new ThreadStart(Listen));
        tcpClientThread.IsBackground = true;
        tcpClientThread.Start();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            SendMessage();
        }
    }

    private void Listen()
    {
        tcpClient = new TcpClient(ipAddress, port);

        byte[] bytes = new byte[1024];
        while (true)
        {
            using (NetworkStream stream = tcpClient.GetStream())
            {
                int length;
                while ((length = stream.Read(bytes, 0, bytes.Length)) != 0)
                {

                    byte[] data = new byte[length];
                    Array.Copy(bytes, 0, data, 0, length);

                    string msg = Encoding.UTF8.GetString(data);
                    Debug.Log("client msg : " + msg);
                }
            }
        }
    }

    private void SendMessage()
    {
        if (tcpClient == null)
        {
            return;
        }
        NetworkStream stream = tcpClient.GetStream();
        if (stream.CanWrite)
        {
            string clientMsg = "hello";
            int size = 5;
            byte[] s = BitConverter.GetBytes(size);
            byte[] msg = Encoding.UTF8.GetBytes(clientMsg);
            //stream.Write(msg, 0, msg.Length);

            byte[] final = Combine(s, msg);
            Debug.Log("string : " + BitConverter.ToString(final));

            stream.Write(final, 0, final.Length);
            Debug.Log("client sent message");
        }
    }

    public static byte[] Combine(byte[] first, byte[] second)
    {
        byte[] ret = new byte[first.Length + second.Length];
        Buffer.BlockCopy(first, 0, ret, 0, first.Length);
        Buffer.BlockCopy(second, 0, ret, first.Length, second.Length);
        return ret;
    }
}

