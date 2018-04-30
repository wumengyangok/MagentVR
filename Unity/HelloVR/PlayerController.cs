namespace GoogleVR.HelloVR {
	using System;
	using UnityEngine;
	using UnityEngine.UI;
	using System.Collections;
	using System.Collections.Generic;
	using System.IO;

	public class PlayerController : MonoBehaviour {

		private GameObject c;
		private GameObject player;
		private Rigidbody rb;
		// Use this for initialization
		void Start () {
//			c = GameObject.Find ("Main Camera");
//			player = GameObject.Find ("Player");
////			camera = GetComponent<Camera> ();
//			rb = player.GetComponent<Rigidbody> ();
		}
		void FixedUpdate () {
//			Debug.Log ("= = " + c.transform.rotation.y.ToString ());
//			Debug.Log ("x = " + Mathf.Sin (c.transform.rotation.y).ToString ());
//			Debug.Log ("y = " + Mathf.Cos (c.transform.rotation.y).ToString ());
//			player.transform.position += new Vector3 ((Mathf.Sin(c.transform.rotation.y * Mathf.PI)), 0f, (Mathf.Cos(c.transform.rotation.y * Mathf.PI))) * Time.deltaTime;
		}
	}
}
