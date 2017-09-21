using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SimpleBehavior : MonoBehaviour {

	public bool ShowGUI;
	public string Message;

	void Awake()
	{
		useGUILayout = ShowGUI;	
	}
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	void OnGUI()
	{
		GUILayout.Label("Hello world");
		if(GUILayout.Button("Find Component"))
		{
			var component = GetComponentInChildren<Text>();
			if(component != null)
			{
				Message = "Find Text";
			}
		}
		GUILayout.Label(Message);
	}
}
