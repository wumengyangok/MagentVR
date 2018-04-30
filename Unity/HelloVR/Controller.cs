namespace GoogleVR.HelloVR {
	using UnityEngine;
	using UnityEngine.UI;
	using System.Collections;
	using System.Collections.Generic;
//	using UnityEditor;
	using System.IO;
	using UnityEngine.Networking;


	public class Controller : MonoBehaviour {

	//	private Rigidbody rb;
	//	private Rigidbody clone;
	//	private int count;
	//	public Text text;
		private static StreamReader reader;
		private GameObject mate;
		private GameObject fire;
		private GameObject enemy;
		private GameObject wall;
		private ParticleSystem exp;
		private ParticleSystem shoot;
		private List<GameElement> wallList;
		private List<GameElement> elementList;
		private int nWall;
		private int nPlayer;
		private int nFrame;
		public static float height = 0.0f;
		public static int WALL = 0;
		public static int MATE = 1;
		public static int ENEMY = 2;
		private int nAction;
		private bool gameOver = false;
		private string[] lines;


		public static Vector3 zero;
		public static Vector3 cameraView;
		public static int rate = 5;
		private GameObject player;

		public static float speed = 1.0f;
		private bool isReadyForNextFrame = true;
		private bool isDuringAction = false;
		public float radius = 5.0F;
		public float power = 10.0F;
		private int maxPlayer;
		private int currentline = 0;

		private int following;
		void PrepareString() {
			string path = "Assets/GoogleVR/Demos/Scripts/HelloVR/video.txt";
			reader = new StreamReader(path);
		}

		private void PrepareStringWeb() {
//			UnityWebRequest www = UnityWebRequest.Get("http://52.10.232.202/JavaUniverse/wp-content/uploads/2018/04/video.txt");
//			yield return www.SendWebRequest();
//
//			if(www.isNetworkError || www.isHttpError) {
//				Debug.Log(www.error);
//			}
//			else {
//				// Show results as text
//				Debug.Log(www.downloadHandler.text);
//
//				// Or retrieve results as binary data
////				byte[] results = www.downloadHandler.data;
//			}

			WWW w = new WWW("http://52.10.232.202/JavaUniverse/wp-content/uploads/2018/04/video.txt");
			while(!w.isDone);
			if (w.error != null) {
				Debug.Log("Error .. " + w.error);
			} else {
				Debug.Log("Found ... ");
			}
			string longStringFromFile = w.text;
			lines = longStringFromFile.Split('\n');
			Debug.Log(longStringFromFile);
		}


		// read in a frame data from in.txt
		void readFrame() {
			for (int i = 0; i < maxPlayer; i++) {
				elementList [i].isAlive = false;
			}
//			string line = reader.ReadLine ();
			if (currentline == lines.Length) {
				gameOver = true;
				return;
			}
//			string[] s = line.Split (' ');
			string[] s = lines[currentline].Split(' ');
			currentline++;
			nPlayer = int.Parse(s [1]);
			nAction = int.Parse(s [2]);
			Debug.Log("number of players: " + nPlayer.ToString() + nAction.ToString());
			for (int i = 0; i < nPlayer; i++) {
//				s = reader.ReadLine ().Split (' ');
				s = lines[currentline].Split(' ');
				currentline++;
				int id = int.Parse (s [0]);
				float x = float.Parse (s [3]);
				float z = float.Parse (s [4]);
				elementList [id].SetTarget (new Vector3 (x, height, z));
				elementList [id].isAlive = true;
				elementList [id].rd.WakeUp ();
				elementList [id].weapon.WakeUp ();
			}
		}

		void readAction() {
			string[] s;
			for (int i = 0; i < nAction; i++) {
				
//				s = reader.ReadLine ().Split (' ');
				s = lines[currentline].Split(' ');
				currentline++;
				int id = int.Parse (s [1]);
				float x = float.Parse (s [2]);
				float z = float.Parse (s [3]);
				elementList [id].SetTarget (new Vector3 (x, height, z));
				elementList [id].fireReady = true;
				elementList [id].weapon.WakeUp ();
			}
		}





		void Start () {
			
			PrepareStringWeb();


			elementList = new List<GameElement> ();
			wallList = new List<GameElement> ();
			mate = GameObject.Find ("Mate");
			wall = GameObject.Find ("Wall");
			enemy = GameObject.Find ("Enemy");
			fire = GameObject.Find ("Fire");
			exp = GameObject.Find ("Exp").GetComponent<ParticleSystem> ();
			shoot = GameObject.Find ("Shoot").GetComponent<ParticleSystem> ();
			exp.Stop ();
//			shoot.Stop ();



			zero = new Vector3 (0.0f, 0.0f, 0.0f);
			cameraView = new Vector3 (1.0f, 1.0f, 1.0f);
			player = GameObject.Find ("Player");
			// Read details of the map

			// Read walls
//			string[] s = reader.ReadLine ().Split (' ');
			string[] s = lines[currentline].Split(' ');
			currentline++;
			nWall = int.Parse (s [1]);
			Debug.Log("number of wall: " + nWall.ToString());
			for (int i = 0; i < nWall; i++) {
//				s = reader.ReadLine ().Split (' ');
				s = lines[currentline].Split(' ');
				currentline++;
				float x = float.Parse (s [0]);
				float z = float.Parse (s [1]);
				Rigidbody rd = Instantiate (wall.GetComponent<Rigidbody> ());
				rd.transform.position = new Vector3(x, height, z);
				wallList.Add (new GameElement (i, rd, WALL, null));
			}

			// Read players
//			s = reader.ReadLine ().Split(' ');
			s = lines[currentline].Split(' ');
			currentline++;
			nPlayer = int.Parse(s [1]);
			maxPlayer = nPlayer;
			nAction = int.Parse(s [2]);
			Debug.Log("number of players: " + nPlayer.ToString() + nAction.ToString());
			for (int i = 0; i < nPlayer; i++) {
				s = lines[currentline].Split(' ');
				currentline++;
//				s = reader.ReadLine ().Split (' ');
				float x = float.Parse (s [3]);
				float z = float.Parse (s [4]);
				Rigidbody rd;
//				ParticleSystem exp;
				Rigidbody weapon = Instantiate (fire.GetComponent<Rigidbody> ());
				weapon.transform.position = new Vector3(x, height, z);
				switch (int.Parse (s [5])) {
					case 0:
						rd = Instantiate (mate.GetComponent<Rigidbody> ());
//						exp = Instantiate (mate.GetComponent<ParticleSystem> ());
//						exp.Stop ();
						rd.transform.position = new Vector3(x, height, z);
//						exp.transform.position = new Vector3(x, height, z);
						elementList.Add (new GameElement (i, rd, MATE, weapon));
						break;
					case 1:
						rd = Instantiate (enemy.GetComponent<Rigidbody> ());
//						exp = Instantiate (mate.GetComponent<ParticleSystem> ());
//						exp.Stop();
						rd.transform.position = new Vector3(x, height, z);
//						exp.transform.position = new Vector3(x, height, z);
						elementList.Add (new GameElement (i, rd, ENEMY, weapon));
						break;
					default:
						break;
				}
			}

			following = 1;
		}








		void FixedUpdate () {
			if (isReadyForNextFrame) {
				isReadyForNextFrame = false;
				if (isDuringAction) {
					readFrame ();
					isDuringAction = false;
				} else {
					readAction ();
					isDuringAction = true;
				}
					
			}
			if (!gameOver) {
				if (!isDuringAction) {
					for (int i = 0; i < maxPlayer; i++) {
						if (!elementList [i].isAlive && !elementList [i].isDestroy) {
							int inc = i;
							while (!elementList [inc].isAlive)
								inc++;
							following = inc;
							ParticleSystem ps = Instantiate (exp);
//							elementList [i].rd.transform.position = elementList [i].rd.transform.position - new Vector3 (0f, 5f, 0f);
							ps.transform.position = elementList [i].rd.transform.position;
							ps.Play ();
							Destroy (elementList [i].rd.gameObject);
//							elementList [i].exp.Play ();
							Destroy (elementList [i].weapon.gameObject);
							elementList [i].isDestroy = true;
						}
						if (elementList [i].isAlive) {
							
							elementList [i].rd.transform.position = 
								Vector3.MoveTowards (elementList [i].rd.transform.position, elementList [i].target, Time.deltaTime * rate);
							elementList [i].weapon.transform.position = 
								Vector3.MoveTowards (elementList [i].weapon.transform.position, elementList [i].target, Time.deltaTime * rate);
//							elementList [i].exp.transform.position = 
//								Vector3.MoveTowards (elementList [i].exp.transform.position, elementList [i].target, Time.deltaTime * rate);
//							if (i == following) {
//								player.transform.position = elementList [i].rd.transform.position + cameraView;
//							}
							if (Vector3.Distance (elementList [i].rd.transform.position, elementList [i].target) < 0.0001f) {
								elementList [i].rd.Sleep ();
								elementList [i].weapon.Sleep ();
							} else if (Vector3.Distance (zero, elementList [i].target) < 0.0001f) {
								elementList [i].rd.Sleep ();
								elementList [i].weapon.Sleep ();
							}
						}
					}
				} else {
					for (int i = 0; i < maxPlayer; i++) {
						if (elementList [i].isAlive && elementList [i].fireReady) {
							elementList [i].weapon.transform.position = 
								Vector3.MoveTowards (elementList [i].weapon.transform.position, elementList [i].target, Time.deltaTime * rate);
							if (Vector3.Distance (elementList [i].weapon.transform.position, elementList [i].target) < 0.0001f) {
								elementList [i].weapon.transform.position = elementList [i].rd.transform.position;
								elementList [i].weapon.Sleep ();
							} else if (Vector3.Distance (zero, elementList [i].target) < 0.0001f) {
								elementList [i].weapon.Sleep ();
							}
						}
					}
				}

				bool isAllSleep = true;
				for (int i = 0; i < maxPlayer; i++) {
					if (elementList [i].isAlive && (!elementList [i].rd.IsSleeping () || !elementList [i].weapon.IsSleeping ())) {
						isAllSleep = false;
					}
				}
				if (isAllSleep) {
					isReadyForNextFrame = true;
				}
			}
				
		}



	}

}
