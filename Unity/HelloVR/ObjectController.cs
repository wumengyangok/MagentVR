// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

namespace GoogleVR.HelloVR {
	using UnityEngine;

	[RequireComponent(typeof(Collider))]
	public class ObjectController : MonoBehaviour {
		private Vector3 startingPosition;
		private Renderer myRenderer;

		public Material inactiveMaterial;
		public Material gazedAtMaterial;

		void Start() {
			startingPosition = transform.localPosition;
			button = GameObject.Find ("Treasure");
			player = GameObject.Find ("Player");
			p = player.GetComponent<Rigidbody> ();
			b = button.GetComponent<Rigidbody> ();
			c = GameObject.Find ("Main Camera");
			isFollowing = false;
			myRenderer = GetComponent<Renderer>();
			SetGazedAt(false);
		}


		private GameObject button;
		private GameObject player;
		private Rigidbody p;
		private Rigidbody b;
		private GameObject c;
		private bool isFollowing;

		void FixedUpdate() {
			gameObject.transform.position = c.transform.position + 
				new Vector3 (5f, 5f, 5f);
			if (isFollowing) {
				player.transform.position += new Vector3 (
					(Mathf.Sin (c.transform.rotation.y * Mathf.PI)), 0f, (Mathf.Cos (c.transform.rotation.y * Mathf.PI)))
					* Time.deltaTime;
			}
		}

		public void SetGazedAt(bool gazedAt) {
			if (inactiveMaterial != null && gazedAtMaterial != null) {
				myRenderer.material = gazedAt ? gazedAtMaterial : inactiveMaterial;
				return;
			}
		}

		public void Hovering() {
			isFollowing = !isFollowing;
			SetGazedAt(false);
		}

		public void Reset() {
			int sibIdx = transform.GetSiblingIndex();
			int numSibs = transform.parent.childCount;
			for (int i=0; i<numSibs; i++) {
				GameObject sib = transform.parent.GetChild(i).gameObject;
				sib.transform.localPosition = startingPosition;
				sib.SetActive(i == sibIdx);
			}
		}

		public void Recenter() {
			#if !UNITY_EDITOR
			GvrCardboardHelpers.Recenter();
			#else
			if (GvrEditorEmulator.Instance != null) {
				GvrEditorEmulator.Instance.Recenter();
			}
			#endif  // !UNITY_EDITOR
		}




	}
}
