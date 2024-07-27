using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public float speed = 5f;

    void Start()
    {
        Application.targetFrameRate = 120;
    }

    void Update()
    {
        if (Input.GetMouseButton(1))
        {
            float xMovement = Convert.ToInt32(Input.GetKey("d")) - Convert.ToInt32(Input.GetKey("a"));
            float yMovement = Convert.ToInt32(Input.GetKey("e")) - Convert.ToInt32(Input.GetKey("q"));
            float zMovement = Convert.ToInt32(Input.GetKey("w")) - Convert.ToInt32(Input.GetKey("s"));
            float speedMultiplier = Input.GetKey(KeyCode.LeftShift) ? 2.0f : 1.0f;
            speedMultiplier *= speed * Time.deltaTime;
            transform.position += transform.right * xMovement * speedMultiplier;
            transform.position += transform.up * yMovement * speedMultiplier;
            transform.position += transform.forward * zMovement * speedMultiplier;

            float xCamMovement = Input.GetAxis("Mouse X");
            float yCamMovement = Input.GetAxis("Mouse Y");
            transform.RotateAround(transform.position, Vector3.up, xCamMovement);
            transform.RotateAround(transform.position, -transform.right, yCamMovement);

            Cursor.lockState = CursorLockMode.Locked;
        }
        else Cursor.lockState = CursorLockMode.None;

        if (Input.GetKey("escape"))
        {
            Application.Quit();
        }
    }
}
