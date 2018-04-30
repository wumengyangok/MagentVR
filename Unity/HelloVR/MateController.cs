namespace GoogleVR.HelloVR {
	using System;
	using UnityEngine;
	using UnityEngine.UI;
	using System.Collections;
	using System.Collections.Generic;
	using System.IO;

	public class MateController : MonoBehaviour {

		private GameObject player;
		// Use this for initialization
		void Start () {
			player = GameObject.Find ("Player");
		}

		public void OnPointerClick () {
			player.transform.position += new Vector3 (10f, 0f, 10f);

		}
	}
}
