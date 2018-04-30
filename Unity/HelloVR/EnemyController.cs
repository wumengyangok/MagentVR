

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
	using System.Collections;
	using System.Collections.Generic;
	using UnityEngine;

	[RequireComponent(typeof(Collider))]
	public class EnemyController : MonoBehaviour {
		private Vector3 startingPosition;
		private Renderer myRenderer;
		private ParticleSystem exp;
		public Material inactiveMaterial;
		public Material gazedAtMaterial;
		public bool onFired;

		void Start() {
			startingPosition = transform.localPosition;
			myRenderer = GetComponent<Renderer>();
			SetGazedAt(false);
			onFired = false;
		}
		public void SetGazedAt(bool gazedAt) {
			
			if (inactiveMaterial != null && gazedAtMaterial != null) {
				myRenderer.material = gazedAt ? gazedAtMaterial : inactiveMaterial;
				return;
			}
		}
		public void onClick() {
			onFired = true;
			exp = Instantiate (GameObject.Find ("Shoot").GetComponent<ParticleSystem> ());
			exp.Play ();
			SetGazedAt(false);
		}

		void FixedUpdate() {
			if (onFired) {
				exp.transform.position = GetComponent<Collider> ().transform.position;
			}
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
