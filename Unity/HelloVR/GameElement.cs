

namespace GoogleVR.HelloVR {
	using System;
	using UnityEngine;
	using UnityEngine.UI;
	using System.Collections;
	using System.Collections.Generic;
	using System.IO;
	public class GameElement {
		public GameElement (int id, Rigidbody rd, int label, Rigidbody weapon) {
			this.id = id;
			this.rd = rd;
			this.label = label;
			this.isAlive = true;
			this.isDestroy = false;
			this.fireReady = false;
			this.weapon = weapon;
		}
		public int id;
		public Rigidbody rd;
		public Rigidbody weapon;
		public int label;
		public Text text;
		public Vector3 target;
		public bool isAlive;
		public bool isDestroy;
		public bool fireReady;
		public void SetText(Text text) {
			this.text = text;
		}
		public void SetTarget(Vector3 target) {
			this.target = target;
		}
	}

}

